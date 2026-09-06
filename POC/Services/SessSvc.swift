//
//  SessSvc.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import ARKit
import AVFoundation
import RealityKit

@MainActor
protocol SessServing: AnyObject {
    var session: ARSession { get }
    
    func start() async -> Bool
    func stop() async
}

@MainActor
final class SessSvc: SessServing {
    let session = ARSession()
    
    private let spatial = SpatialTrackingSession()
    private var running = false
    
    func start() async -> Bool {
        guard !running else {
            return true
        }
        
        guard await cameraAccess() else {
            print("CAMERA: permission denied")
            return false
        }
        
        let classified = ARWorldTrackingConfiguration.supportsSceneReconstruction(
            .meshWithClassification
        )
        
        let plain = ARWorldTrackingConfiguration.supportsSceneReconstruction(
            .mesh
        )
        
        guard classified || plain else {
            print("LIDAR: scene reconstruction unsupported")
            return false
        }
        
        let arConfig = makeARConfig(
            classified: classified,
            plain: plain
        )
        
        let spatialConfig = SpatialTrackingSession.Configuration(
            tracking: [
                .camera,
                .world,
                .plane
            ],
            sceneUnderstanding: [
                .collision,
                .occlusion
            ],
            camera: .back
        )
        
        session.run(
            arConfig,
            options: [
                .resetTracking,
                .removeExistingAnchors
            ]
        )
        
        let unavailable = await runSpatial(
            spatialConfig,
            arConfig: arConfig
        )
        
        if let unavailable {
            print("SPATIAL: unavailable anchors \(unavailable.anchor)")
            
            if unavailable.missingCameraAuthorization == true {
                print("SPATIAL: camera authorization missing")
                session.pause()
                return false
            }
            
            if unavailable.anchor.contains(.camera) {
                print("SPATIAL: camera capability unavailable")
                session.pause()
                return false
            }
            
            if unavailable.anchor.contains(.world) {
                print("SPATIAL: world tracking unavailable")
                session.pause()
                return false
            }
            
            if unavailable.anchor.contains(.plane) {
                print("SPATIAL: plane tracking unavailable")
            }
            
            if !unavailable.sceneUnderstanding.isEmpty {
                print(
                    "SPATIAL scene understanding unavailable:",
                    unavailable.sceneUnderstanding
                )
            }
        }
        
        running = true
        
        print("CAMERA: authorized")
        print("ARSession: running")
        print("SpatialTrackingSession: running")
        
        return true
    }
    
    func stop() async {
        guard running else {
            return
        }
        
        running = false
        
        await spatial.stop()
        session.pause()
        
        print("SpatialTrackingSession: stopped")
        print("ARSession: stopped")
    }
    
    /// The `ARSession`-backed overload ships only in the device SDK
    /// Unreachable on the simulator anyway (no scene reconstruction), but
    /// keeping it compiling lets the menu screens run there
    private func runSpatial(
        _ config: SpatialTrackingSession.Configuration,
        arConfig: ARWorldTrackingConfiguration
    ) async -> SpatialTrackingSession.UnavailableCapabilities? {
#if targetEnvironment(simulator)
        await spatial.run(config)
#else
        await spatial.run(
            config,
            session: session,
            arConfiguration: arConfig
        )
#endif
    }

    private func cameraAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("CAMERA status: authorized")
            return true
            
        case .notDetermined:
            print("CAMERA status: requesting")
            
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            
            print(
                granted
                ? "CAMERA permission: granted"
                : "CAMERA permission: denied"
            )
            
            return granted
            
        case .denied:
            print("CAMERA status: denied")
            return false
            
        case .restricted:
            print("CAMERA status: restricted")
            return false
            
        @unknown default:
            print("CAMERA status: unknown")
            return false
        }
    }
    
    private func makeARConfig(
        classified: Bool,
        plain: Bool
    ) -> ARWorldTrackingConfiguration {
        let config = ARWorldTrackingConfiguration()
        
        config.worldAlignment = .gravity
        
        config.planeDetection = [
            .horizontal,
            .vertical
        ]
        
        config.environmentTexturing = .none
        config.videoHDRAllowed = false
        config.providesAudioData = false
        
        if classified {
            config.sceneReconstruction = .meshWithClassification
        } else if plain {
            config.sceneReconstruction = .mesh
        }
        
        return config
    }
}
