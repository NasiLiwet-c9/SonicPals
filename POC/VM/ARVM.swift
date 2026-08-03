//
//  ARVM.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Asaryun on 02/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

import Observation
import RealityKit

@MainActor
@Observable
final class ARVM {
    private(set) var state = ARState()
    
    @ObservationIgnored
    private let ctrl:
    any SceneControlling
    
    init() {
        let waveShape = WaveShape()
        let coneShape = FPConeShape()
        
        let meshRead = FPMeshRead()
        
        let meshPack = FPMeshPack(
            liftM: 0.018
        )
        
        let meshFact = FPMeshFact()
        
        let meshBuild = FPMeshBuild(
            read: meshRead,
            pack: meshPack,
            fact: meshFact
        )
        
        let ctrl = SceneCtrl(
            sess: ARSessSvc(),
            placeSvc: PlaceSvc(),
            objectMaker: ObjectMaker(),
            waveSim: WaveSim(),
            
            fpCone: FPConeDraw(
                shape: coneShape
            ),
            
            fpMesh: meshBuild,
            
            waveDraw: WaveDraw(
                shape: waveShape
            )
        )
        
        self.ctrl = ctrl
        
        ctrl.onState = {
            [weak self] state in
            
            self?.state = state
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
    
    func handleMemoryWarning() {
        ctrl.handleMemoryWarning()
    }
}
