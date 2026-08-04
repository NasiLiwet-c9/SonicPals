//
//  SceneCtrl.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Asaryun on 02/08/26.
<<<<<<< HEAD
//  Updated by Shanon Newcastle on 03/08/26.
//  Updated by Asaryun on 03/08/26.

=======
//  Updated by Shanon Newcastle on 04/08/26.
//
>>>>>>> shan_POC

import RealityKit
import UIKit
import simd

@MainActor
final class SceneCtrl:
    NSObject,
    SceneControlling,
    UIGestureRecognizerDelegate {
    
    var onState:
    ((ARState) -> Void)?
    
    weak var ar: ARView?
    
    let sess:
    any ARSessionServing
    
    let objectMaker:
    any ObjectMaking
    
    let tpSpawn:
    any TPSpawning
    
    let waveSim:
    any WaveSimulating
    
    let fpCone:
    any FPConeDrawing
    
    let fpMesh:
    any FPMeshBuilding
    
    let waveDraw:
    any WaveDrawing
    
    let world = AnchorEntity(
        world: .zero
    )
    
    var state = ARState()
    
    var object: Entity?
    var waveStart: Entity?
    
    var fpRoot: Entity?
    var tpWave: Entity?
    
    var lastData: WaveData?
    var visTask:
    Task<Void, Never>?
    
    var isPlacing = false
    
    var dragStart:
    SIMD3<Float>?
    
    var yaw: Float = 0
    
    init(
        sess: any ARSessionServing,
        objectMaker: any ObjectMaking,
        tpSpawn: any TPSpawning,
        waveSim: any WaveSimulating,
        fpCone: any FPConeDrawing,
        fpMesh: any FPMeshBuilding,
        waveDraw: any WaveDrawing
    ) {
        self.sess = sess
        self.objectMaker = objectMaker
        self.tpSpawn = tpSpawn
        self.waveSim = waveSim
        self.fpCone = fpCone
        self.fpMesh = fpMesh
        self.waveDraw = waveDraw
        
        super.init()
    }
    
    func setup(
        _ view: ARView
    ) {
        guard ar == nil else {
            return
        }
        
        ar = view
        
        let supported = sess.start(
            view
        )
        
        view.scene.addAnchor(
            world
        )
        
<<<<<<< HEAD
        state.lidarOK =
        supported
        
        state.meshOn =
        false
=======
        state.lidarOK = supported
        state.meshOn = false
>>>>>>> shan_POC
        
        state.msg = supported
        ? "BAT VISION ready, move phone to aim"
        : "LiDAR scene reconstruction unavailable"
        
        sess.showMesh(
            false,
            in: view
        )
        
        sess.addCoach(
            to: view
        )
        
        addPan(
            to: view
        )
        
        push()
        
        // Preload Bat3 before the user presses Place.
        Task { [weak self] in
            guard let self else {
                return
            }
            
            _ = await self
                .objectMaker
                .prepare()
        }
    }
    
    func toggleMesh() {
        guard state.viewMode == .third else {
            setMsg(
                "The full mesh stays hidden in BAT VISION"
            )
            return
        }
        
        guard let ar,
              state.lidarOK else {
            return
        }
        
        state.meshOn.toggle()
        
        sess.showMesh(
            state.meshOn,
            in: ar
        )
        
        setMsg(
            state.meshOn
            ? "Mesh visible"
            : "Mesh hidden"
        )
    }
    
    func handleMemoryWarning() {
        clearWave()
        
        if let ar {
            sess.showMesh(
                false,
                in: ar
            )
        }
        
        state.meshOn = false
        state.pointsOn = false
        
        setMsg(
            "Temporary wave graphics cleared"
        )
    }
    
    func addPan(
        to view: ARView
    ) {
        let pan =
        UIPanGestureRecognizer(
            target: self,
            action: #selector(
                drag(_:)
            )
        )
        
        pan.cancelsTouchesInView =
        false
        
        pan.maximumNumberOfTouches =
        1
        
        pan.delegate = self
        
        view.addGestureRecognizer(
            pan
        )
    }
    
    func clearWave() {
        visTask?.cancel()
        visTask = nil
        
        fpRoot?.removeFromParent()
        tpWave?.removeFromParent()
        
        fpRoot = nil
        tpWave = nil
        lastData = nil
        
        state.hasWave = false
    }
    
    func setMsg(
        _ text: String
    ) {
        state.msg = text
        push()
    }
    
    func push() {
        onState?(
            state
        )
    }
    
    nonisolated func gestureRecognizer(
        _ gestureRecognizer:
        UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer:
        UIGestureRecognizer
    ) -> Bool {
        true
    }
}
