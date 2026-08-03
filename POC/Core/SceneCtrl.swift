//
//  SceneCtrl.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Asaryun on 02/08/26.
//  Updated by Shanon Newcastle on 03/08/26.
//

import RealityKit
import UIKit
import simd

@MainActor
final class SceneCtrl:
    NSObject,
    SceneControlling,
    UIGestureRecognizerDelegate {
    
    var onState: ((ARState) -> Void)?
    
    weak var ar: ARView?
    
    let sess: any ARSessionServing
    let placeSvc: any PlaceServing
    let objectMaker: any ObjectMaking
    let waveSim: any WaveSimulating
    let waveDraw: any WaveDrawing
    
    let world = AnchorEntity(
        world: .zero
    )
    
    var state = ARState()
    
    var object: Entity?
    var waveStart: Entity?
    var wave: Entity?
    var lastData: WaveData?
    
    var yaw: Float = 0
    
    init(
        sess: any ARSessionServing,
        placeSvc: any PlaceServing,
        objectMaker: any ObjectMaking,
        waveSim: any WaveSimulating,
        waveDraw: any WaveDrawing
    ) {
        self.sess = sess
        self.placeSvc = placeSvc
        self.objectMaker = objectMaker
        self.waveSim = waveSim
        self.waveDraw = waveDraw
        
        super.init()
    }
    
    func setup(_ view: ARView) {
        guard ar == nil else {
            return
        }
        
        ar = view
        
        let supported =
        sess.start(view)
        
        view.scene.addAnchor(
            world
        )
        
        state.lidarOK =
        supported
        
        state.meshOn =
        supported
        
        state.msg =
        supported
        ? "FIRST POV ready, move phone to aim"
        : "LiDAR scene reconstruction unavailable"
        
        sess.addCoach(
            to: view
        )
        
        addPan(
            to: view
        )
        
        push()
    }
    
    func toggleMesh() {
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
    
    func addPan(to view: ARView) {
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
        
        pan.delegate =
        self
        
        view.addGestureRecognizer(
            pan
        )
    }
    
    func removeWave() {
        wave?.removeFromParent()
        
        wave = nil
        state.hasWave = false
    }
    
    func clearWave() {
        removeWave()
        lastData = nil
    }
    
    func setMsg(_ text: String) {
        state.msg = text
        push()
    }
    
    func push() {
        onState?(state)
    }
    
    nonisolated func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
