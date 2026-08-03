//
//  ARVM.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Asaryun on 02/08/26.
//  Updated by Shanon Newcastle on 03/08/26.
//

import Observation
import RealityKit

@MainActor
@Observable
final class ARVM {
    private(set) var state =
    ARState()
    
    @ObservationIgnored
    private let ctrl:
    any SceneControlling
    
    init() {
        let shape =
        WaveShape()
        
        let draw =
        WaveDraw(
            shape: shape
        )
        
        let ctrl =
        SceneCtrl(
            sess: ARSessSvc(),
            placeSvc: PlaceSvc(),
            objectMaker: ObjectMaker(),
            waveSim: WaveSim(),
            waveDraw: draw,
            pulseFX: PulseFX(),
            beamFX: BeamFX(
                shape: shape
            )
        )
        
        self.ctrl =
        ctrl
        
        ctrl.onState = {
            [weak self] state in
            
            self?.state =
            state
        }
    }
    
    func setup(
        _ view: ARView
    ) {
        ctrl.setup(view)
    }
    
    func place() {
        ctrl.place()
    }
    
    func sendWave() {
        ctrl.sendWave()
    }
    
    func turn(
        _ deg: Float
    ) {
        ctrl.turn(deg)
    }
    
    func toggleMesh() {
        ctrl.toggleMesh()
    }
    
    func togglePoints() {
        ctrl.togglePoints()
    }
    
    func toggleView() {
        ctrl.toggleView()
    }
    
    func clear() {
        ctrl.clear()
    }
}
