//
//  ECSWorld.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import Foundation
import Observation
import RealityKit
import SonarCore
import simd

@MainActor
@Observable
final class ECSWorld {
    private(set) var model = AppModel()

    let anchor = AnchorEntity(world: .zero)
    let sessEntity = Entity()
    let scanEntity = Entity()

    /// Rides the camera, so it needs its own anchor
    let guideAnchor = GuideArrow.makeAnchor()

    var targetEntity: Entity?
    var eatCandidate: Entity?

    /// Built and parented but disabled, so spawning is a move and an
    /// enable. No `TargetComp`, so no system sees it yet
    var stagedTarget: TargetPart?
    var lastTargetPos: SIMD3<Float>?

    private var started = false
    private var foundTask: Task<Void, Never>?
    private var eatReadyTask: Task<Void, Never>?
    private var eatLostTask: Task<Void, Never>?
    private var scanTask: Task<Void, Never>?
    private var cueTask: Task<Void, Never>?

    /// Quest rules, kept out of this type
    let mission = MissionSvc()

    /// First-run coaching, woven into the live session
    let coach = CoachSvc()

    let sess: any SessServing
    let sfx = SfxSvc.shared
    let haptic = HapticSvc.shared
    let waveSim: any WaveSimulating
    let targetMaker: any TargetMaking
    let targetSpawn: any TargetSpawning
    let targetWave: any TargetWaveChecking
    let targetReserve = TargetReserveSvc()

    init() {
        let sess = SessSvc()
        self.sess = sess

        waveSim = WaveSim(rayMaker: RayMaker(rings: 5), maxDistance: 1.5)
        targetMaker = TargetAssetSvc.shared
        targetSpawn = TargetSpawnSvc()
        targetWave = TargetWaveSvc()

        sessEntity.components.set(SessComp(session: ARSessionRef(sess.session)))
        scanEntity.name = "fpScan"
        scanEntity.components.set(FPScanComp())

        anchor.addChild(sessEntity)
        anchor.addChild(scanEntity)

        mission.attach(to: self)
        coach.attach(to: self)

        watchTarget()
        watchMangoEat()
        watchScan()
        watchCues()
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
            coach.noteSessionReady()
            startScan()

            if await targetMaker.prepare() {
                await targetMaker.prewarm()
            }

            stageTarget()
        } else {
            started = false
            model.msg = "Camera or LiDAR unavailable"
        }
    }

    func stop() async {
        guard started else { return }

        started = false
        mission.cancel()
        coach.suspend()

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

    /// Lets the ECS systems see a lesson is running
    func setTeaching(_ on: Bool) {
        guard var comp = sessEntity.components[SessComp.self] else { return }

        comp.teaching = on
        sessEntity.components[SessComp.self] = comp
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

        mission.cancel()
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
                mission.showFoundTreeDialogue()
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
                coach.noteEatReady()
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

    private func watchCues() {
        cueTask = Task { @MainActor [weak self] in
            for await note in NotificationCenter.default.notifications(named: .targetCue) {
                guard let self, let cue = note.object as? TargetCue else { continue }

                mission.show(cue)
            }
        }
    }

    private func watchScan() {
        scanTask = Task { @MainActor [weak self] in
            for await note in NotificationCenter.default.notifications(named: .fpScanUpdate) {
                guard let self, let hud = note.object as? FPScanHUD else { continue }

                model.scanProgress = hud.progress
                model.scanTurn = hud.turn
                coach.noteScan(progress: hud.progress)

                if hud.ready {
                    await finishScanTarget()
                } else {
                    prepScanTarget(progress: hud.progress)
                }
            }
        }
    }
}

// MARK: - CoachHost

extension ECSWorld: CoachHost {
    func startHunt() {
        mission.startHunt()
    }

    func playCoachCue() {
        sfx.dialogue()
    }
}
