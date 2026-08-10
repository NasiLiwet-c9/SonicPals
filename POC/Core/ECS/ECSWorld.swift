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

    weak var ar: ARView?

    let anchor = AnchorEntity(world: .zero)
    let sessEntity = Entity()

    var targetEntity: Entity?

    private var foundTask: Task<Void, Never>?

    let sess: any SessServing
    let waveSim: any WaveSimulating

    let targetMaker: any TargetMaking
    let targetSpawn: any TargetSpawning
    let targetWave: any TargetWaveChecking

    init() {
        sess = SessSvc()

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

        FPRevealSys.registerSystem()
        TargetSys.registerSystem()

        sessEntity.components.set(
            SessComp()
        )

        watchTarget()
    }

    func setup(_ view: ARView) {
        guard ar == nil else {
            return
        }

        ar = view

        let supported = sess.start(view)

        view.scene.addAnchor(anchor)
        anchor.addChild(sessEntity)

        var comp =
            sessEntity.components[SessComp.self]
            ?? SessComp()

        comp.lidarOK = supported

        sessEntity.components[SessComp.self] = comp

        model.lidarOK = supported
        model.msg = supported ? "" : "LiDAR is required"

        sess.addCoach(to: view)

        Task { [weak self] in
            guard let self else {
                return
            }

            _ = await self.targetMaker.prepare()
        }
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
        let active =
            anchor.children.filter {
                $0.components.has(
                    RevealComp.self
                )
            }

        for entity in active {
            entity.removeFromParent()
        }
    }

    func clearTraces() {
        let traces =
            anchor.children.filter {
                $0.components.has(
                    TraceComp.self
                )
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
                      self.targetEntity === target else {
                    continue
                }

                self.model.targetFound = true
                self.setMsg("Found it!")
            }
        }
    }
}
