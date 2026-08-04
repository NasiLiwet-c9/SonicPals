//
//  ARSessSvc.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
<<<<<<< HEAD
//  Updated by Shanon Newcastle on 03/08/26.
//  Updated by Asaryun on 03/08/26.
=======
//  Updated by Shanon Newcastle on 04/08/26.
//
>>>>>>> shan_POC

import ARKit
import RealityKit
import UIKit

@MainActor
final class ARSessSvc: ARSessionServing {
    func start(
        _ view: ARView
    ) -> Bool {
        let config = ARWorldTrackingConfiguration()
        
        config.planeDetection = [
            .horizontal,
            .vertical
        ]
        
        config.environmentTexturing = .none
        config.videoHDRAllowed = false
        
        if let format = balancedFormat() {
            config.videoFormat = format
        }
        
        let supported =
        ARWorldTrackingConfiguration
            .supportsSceneReconstruction(.mesh)
        
        if supported {
            config.sceneReconstruction = .mesh
            
            view.environment
                .sceneUnderstanding
                .options = [
                    .collision,
                    .occlusion
                ]
<<<<<<< HEAD
            
//            showMesh(
//                true,
//                in: view
//            )
=======
>>>>>>> shan_POC
        }
        
        reduceCost(in: view)
        showMesh(false, in: view)
        
        view.session.run(
            config,
            options: [
                .resetTracking,
                .removeExistingAnchors
            ]
        )
        
        return supported
    }
    
    func showMesh(
        _ show: Bool,
        in view: ARView
    ) {
        if show {
            view.debugOptions.insert(
                .showSceneUnderstanding
            )
        } else {
            view.debugOptions.remove(
                .showSceneUnderstanding
            )
        }
    }
    
    func addCoach(
        to view: ARView
    ) {
        let coach = ARCoachingOverlayView()
        
        coach.session = view.session
        coach.goal = .horizontalPlane
        coach.activatesAutomatically = true
        coach.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(coach)
        
        NSLayoutConstraint.activate([
            coach.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            coach.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),
            coach.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            coach.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            )
        ])
    }
    
    private func balancedFormat()
    -> ARConfiguration.VideoFormat? {
        
        let formats =
        ARWorldTrackingConfiguration
            .supportedVideoFormats
            .filter {
                $0.framesPerSecond == 30
            }
            .sorted {
                let first =
                $0.imageResolution.width
                * $0.imageResolution.height
                
                let second =
                $1.imageResolution.width
                * $1.imageResolution.height
                
                return first < second
            }
        
        return formats.first {
            $0.imageResolution.width >= 1_280
        } ?? formats.first
    }
    
    private func reduceCost(
        in view: ARView
    ) {
        view.renderOptions.insert(
            .disableCameraGrain
        )
        
        view.renderOptions.insert(
            .disableMotionBlur
        )
        
        view.renderOptions.insert(
            .disableHDR
        )
    }
}
