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
    var eatCandidate: Entity?
    
    private var started = false
    private var foundTask: Task<Void, Never>?
    private var eatReadyTask: Task<Void, Never>?
    private var eatLostTask: Task<Void, Never>?
    
    let sess: any SessServing
    let sfx = SfxSvc()
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
            sceneName: "Mango+Tree",
            treeH: 1.80
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
        watchMangoEat()
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
            sfx.startAmbience()
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
        sfx.stopAmbience()
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
            
        case .eatMango:
            eatMango()
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
        eatCandidate = nil
        
        model.hasTarget = false
        model.targetFound = false
        model.mangoEatReady = false
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
    
    private func watchMangoEat() {
        eatReadyTask = Task { @MainActor [weak self] in
            for await note in NotificationCenter.default.notifications(
                named: .mangoEatReady
            ) {
                guard let self,
                      let mango = note.object as? Entity
                else {
                    continue
                }
                
                eatCandidate = mango
                model.mangoEatReady = true
            }
        }
        
        eatLostTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(
                named: .mangoEatLost
            ) {
                guard let self else {
                    continue
                }
                
                eatCandidate = nil
                model.mangoEatReady = false
            }
        }
    }
}
