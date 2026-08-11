//
//  ECSWorld.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import Foundation
import Observation
import RealityKit

@MainActor
@Observable
final class ECSWorld {
    private(set) var model = AppModel()
    
    let anchor = AnchorEntity(world: .zero)
    let sessEntity = Entity()
    
    var targetEntity: Entity?
    
    private var started = false
    private var foundTask: Task<Void, Never>?
    
    let sess: any SessServing
    let waveSim: any WaveSimulating
    
    let targetMaker: any TargetMaking
    let targetSpawn: any TargetSpawning
    let targetWave: any TargetWaveChecking
    
    init() {
        let sess = SessSvc()
        self.sess = sess
        
        waveSim = WaveSim(
            rayMaker: RayMaker(rings: 5),
            maxDistance: 1.5
        )
        
        targetMaker = TargetAssetSvc(
            treeName: "Stylized_Tree",
            mangoName: "Mango",
            treeH: 1.80,
            mangoSpan: 0.14
        )
        
        targetSpawn = TargetSpawnSvc(
            minM: 1.8,
            maxM: 3.2
        )
        
        targetWave = TargetWaveSvc()
        
        sessEntity.components.set(
            SessComp(
                session: ARSessionRef(sess.session)
            )
        )
        
        anchor.addChild(sessEntity)
        
        watchTarget()
    }
    
    func start() async {
        guard !started else {
            return
        }
        
        let supported = await sess.start()
        
        guard var comp = sessEntity.components[SessComp.self] else {
            return
        }
        
        comp.lidarOK = supported
        sessEntity.components[SessComp.self] = comp
        
        model.lidarOK = supported
        
        if supported {
            started = true
            model.msg = ""
            _ = await targetMaker.prepare()
        } else {
            started = false
            model.msg = "Camera or LiDAR unavailable"
        }
    }
    
    func stop() async {
        guard started else {
            return
        }
        
        started = false
        await sess.stop()
    }
    
    func perform(_ cmd: ECSCmd) {
        switch cmd {
        case .spawnTarget:
            spawnTarget()
            
        case .sendWave:
            sendWave()
            
        case .toggleDim:
            model.dimOn.toggle()
            
        case .clear:
            clear()
            
        case .memoryWarning:
            clearActiveWave()
            clearTraces()
        }
    }
    
    func setMsg(_ text: String) {
        model.msg = text
    }
    
    func clearActiveWave() {
        let active = anchor.children.filter {
            $0.components.has(RevealComp.self)
        }
        
        for entity in active {
            entity.removeFromParent()
        }
    }
    
    func clearTraces() {
        let traces = anchor.children.filter {
            $0.components.has(TraceComp.self)
        }
        
        for entity in traces {
            entity.removeFromParent()
        }
    }
    
    func clear() {
        clearActiveWave()
        clearTraces()
        
        targetEntity?.removeFromParent()
        targetEntity = nil
        
        model.hasTarget = false
        model.targetFound = false
        model.msg = ""
    }
    
    private func watchTarget() {
        foundTask = Task { @MainActor [weak self] in
            for await note in NotificationCenter.default.notifications(
                named: .targetFound
            ) {
                guard let self,
                      let target = note.object as? Entity,
                      self.targetEntity === target
                else {
                    continue
                }
                
                model.targetFound = true
                setMsg("Tree Found!")
            }
        }
    }
}
