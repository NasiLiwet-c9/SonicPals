//
//  ECSWorld.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import Foundation
import Observation
import RealityKit
import simd

@MainActor
@Observable
final class ECSWorld {
    private(set) var model = AppModel()

    let anchor = AnchorEntity(world: .zero)
    let sessEntity = Entity()
    let scanEntity = Entity()

    var targetEntity: Entity?
    var eatCandidate: Entity?
    var missionTask: Task<Void, Never>?
    var lastTargetPos: SIMD3<Float>?

    private var started = false
    private var foundTask: Task<Void, Never>?
    private var eatReadyTask: Task<Void, Never>?
    private var eatLostTask: Task<Void, Never>?
    private var scanTask: Task<Void, Never>?

    let sess: any SessServing
    let sfx = SfxSvc.shared
    let waveSim: any WaveSimulating
    let targetMaker: any TargetMaking
    let targetSpawn: any TargetSpawning
    let targetWave: any TargetWaveChecking
    let targetReserve = TargetReserveSvc()

    init() {
        let sess = SessSvc()
        self.sess = sess

        waveSim = WaveSim(rayMaker: RayMaker(rings: 5), maxDistance: 1.5)
        targetMaker = TargetAssetSvc(sceneName: "Mango+Tree", treeH: TargetCfg.Tree.height)
        targetSpawn = TargetSpawnSvc()
        targetWave = TargetWaveSvc()

        sessEntity.components.set(SessComp(session: ARSessionRef(sess.session)))
        scanEntity.name = "fpScan"
        scanEntity.components.set(FPScanComp())

        anchor.addChild(sessEntity)
        anchor.addChild(scanEntity)

        watchTarget()
        watchMangoEat()
        watchScan()
    }

    func start() async {
        guard !started else { return }

        let supported = await sess.start()

        guard var comp = sessEntity.components[SessComp.self] else { return }

        comp.lidarOK = supported
        sessEntity.components[SessComp.self] = comp
        model.lidarOK = supported

        if supported {
            started = true
            model.msg = ""
            sfx.startAmbience()
            startScan()
            _ = await targetMaker.prepare()
        } else {
            started = false
            model.msg = "Camera or LiDAR unavailable"
        }
    }

    func stop() async {
        guard started else { return }

        started = false
        missionTask?.cancel()
        missionTask = nil

        targetReserve.clear()
        clearActiveWave()
        clearTraces()
        endScan()

        sfx.stopAmbience()
        await sess.stop()
    }

    func startScan() {
        guard var comp = scanEntity.components[FPScanComp.self] else { return }

        clearScanVisuals()

        comp.resetID += 1
        comp.active = true
        scanEntity.components[FPScanComp.self] = comp
        scanEntity.isEnabled = true

        targetReserve.clear()
        model.scanReady = false
        model.scanProgress = 0
        model.scanTurn = .none
    }

    func endScan() {
        guard var comp = scanEntity.components[FPScanComp.self] else { return }

        comp.active = false
        scanEntity.components[FPScanComp.self] = comp
        scanEntity.isEnabled = false

        clearScanVisuals()
    }

    private func clearScanVisuals() {
        let old = scanEntity.children.filter {
            $0.name == "scanFloor" || $0.name == "scanMesh"
        }

        for entity in old {
            entity.removeFromParent()
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
        case .eatMango:
            eatMango()
        }
    }

    func setMsg(_ text: String) {
        model.msg = text
    }

    func clearActiveWave() {
        let active = anchor.children.filter { $0.components.has(RevealComp.self) }
        for entity in active {
            entity.removeFromParent()
        }
    }

    func clearTraces() {
        let traces = anchor.children.filter { $0.components.has(TraceComp.self) }
        for entity in traces {
            entity.removeFromParent()
        }
    }

    func clear() {
        clearActiveWave()
        clearTraces()

        missionTask?.cancel()
        missionTask = nil
        targetReserve.clear()

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
            for await note in NotificationCenter.default.notifications(named: .targetFound) {
                guard let self,
                      let target = note.object as? Entity,
                      self.targetEntity === target else { continue }

                model.targetFound = true
                setMsg("")
                sfx.treeFound()
                showFoundTreeDialogue()
            }
        }
    }

    private func watchMangoEat() {
        eatReadyTask = Task { @MainActor [weak self] in
            for await note in NotificationCenter.default.notifications(named: .mangoEatReady) {
                guard let self, let mango = note.object as? Entity else { continue }

                if !model.mangoEatReady {
                    sfx.mangoReady()
                }

                eatCandidate = mango
                model.mangoEatReady = true
            }
        }

        eatLostTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .mangoEatLost) {
                guard let self else { continue }

                eatCandidate = nil
                model.mangoEatReady = false
            }
        }
    }

    private func watchScan() {
        scanTask = Task { @MainActor [weak self] in
            for await note in NotificationCenter.default.notifications(named: .fpScanUpdate) {
                guard let self, let hud = note.object as? FPScanHUD else { continue }

                model.scanProgress = hud.progress
                model.scanTurn = hud.turn

                if hud.ready {
                    await finishScanTarget()
                } else {
                    prepScanTarget(progress: hud.progress)
                }
            }
        }
    }
}
