//
//  ECSWorld+Spawn.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import Foundation
import RealityKit
import simd

extension ECSWorld {
    func spawnTargetNow(showError: Bool) async -> Bool {
#if DEBUG
        if forceSpawnActive {
            return await forceSpawnTargetNow(showError: showError)
        }
#endif

        guard model.lidarOK,
              let scene = anchor.scene,
              var sessComp = sessEntity.components[SessComp.self],
              !sessComp.spawning else {
            return false
        }

        sessComp.spawning = true
        sessEntity.components[SessComp.self] = sessComp

        if showError { setMsg("") }

        defer {
            if var comp = sessEntity.components[SessComp.self] {
                comp.spawning = false
                sessEntity.components[SessComp.self] = comp
            }
        }

        guard await targetMaker.prepare() else {
            if showError { setMsg(targetMaker.loadError ?? "Target could not load") }
            return false
        }

        guard let pose = nextTargetPose(scene: scene) else {
            if showError { setMsg("Scan more open floor first") }
            return false
        }

        guard let part = nextTargetPart() else {
            if showError { setMsg(targetMaker.loadError ?? "Target could not load") }
            return false
        }

        installTarget(part, pose: pose)
        return true
    }

    /// Prefers the staged one, builds only if staging fell behind
    private func nextTargetPart() -> TargetPart? {
        if let staged = stagedTarget {
            stagedTarget = nil
            return staged
        }

        return targetMaker.make()
    }

    /// Parented now and disabled, so the scene work is off the frame
    /// where it appears
    func stageTarget() {
        guard stagedTarget == nil,
              model.lidarOK,
              let part = targetMaker.make() else {
            return
        }

        part.root.isEnabled = false
        anchor.addChild(part.root)

        stagedTarget = part
    }

    private func nextTargetPose(scene: Scene) -> TargetPose? {
        if let pose = targetReserve.take() {
#if DEBUG
            print("[TARGET SPAWN] USING RESERVED SCAN POSE")
#endif
            return pose
        }

        guard let pose = targetSpawn.pose(
            session: sess.session,
            scene: scene,
            height: TargetCfg.Tree.height
        ) else {
            return nil
        }

        guard let lastTargetPos else { return pose }

        return distXZ(pose.pos, lastTargetPos) >= TargetCfg.Spawn.repeatDistance ? pose : nil
    }

    private func installTarget(_ part: TargetPart, pose: TargetPose) {
        clearActiveWave()
        clearTraces()

        if targetEntity !== part.root {
            targetEntity?.removeFromParent()
        }

        part.root.stopAllAnimations(recursive: true)

        part.root.components[TargetComp.self] = TargetComp(
            real: part.real,
            parts: part.parts,
            lockPos: pose.pos,
            lockYaw: pose.yaw
        )

        // Already parented when it was staged
        if part.root.parent !== anchor {
            anchor.addChild(part.root)
        }

        part.root.setPosition(pose.pos, relativeTo: nil)

        part.root.setOrientation(
            simd_quatf(angle: pose.yaw, axis: SIMD3<Float>(0, 1, 0)),
            relativeTo: nil
        )

        part.root.isEnabled = true

        targetEntity = part.root
        lastTargetPos = pose.pos
        model.hasTarget = true
        model.targetFound = false
        model.mangoEatReady = false
        model.msg = ""

        // Stage the next one while the player hunts this one
        Task { @MainActor [weak self] in
            guard let self else { return }

            await targetMaker.prewarm()
            stageTarget()
        }

#if DEBUG
        let p = part.root.position(relativeTo: nil)
        print("[TARGET DEBUG] TARGET INSTALLED")
        print("[TARGET DEBUG] x=\(p.x) y=\(p.y) z=\(p.z)")
#endif
    }

    private func distXZ(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        simd_length(SIMD2<Float>(a.x - b.x, a.z - b.z))
    }

    /// Player-facing respawn: re-sweeps, then moves the tree
    ///
    /// Still uses the normal safe-pose search, and keeps `lastTargetPos`
    /// so `repeatDistance` pushes it away from where they gave up
    func respawnTarget() {
        guard model.hudStage == .mission,
              !model.missionComplete else {
            return
        }

        clearActiveWave()
        clearTraces()

        targetEntity?.removeFromParent()
        targetEntity = nil
        eatCandidate = nil

        model.hasTarget = false
        model.targetFound = false
        model.mangoEatReady = false
        model.msg = ""

        rescanFloor()
        mission.requestTarget()
    }

    /// Restarts floor sampling without touching the HUD
    private func rescanFloor() {
        guard var comp = scanEntity.components[FPScanComp.self] else { return }

        targetReserve.clear()

        comp.resetID += 1
        comp.active = true

        scanEntity.components[FPScanComp.self] = comp
        scanEntity.isEnabled = true
    }

    // MARK: - Scan preflight

    func prepScanTarget(progress: Float) {
        guard progress >= TargetCfg.Preflight.startProgress else { return }
        guard !targetReserve.ready else { return }
        guard targetReserve.canCheck() else { return }

        _ = reserveScanTarget()
    }

    func finishScanTarget() async {
        targetReserve.clearPose()

        if targetReserve.canCheck(force: true),
           reserveScanTarget() {
            finishScanReady()
            return
        }

        model.scanProgress = TargetCfg.Preflight.waitingProgress
        model.scanTurn = .none
        model.msg = "Scan a little more open floor."

        resumeOpenScan()

#if DEBUG
        print("[TARGET PREP] NO SAFE POSE - SCAN RESUMED")
#endif

        while !Task.isCancelled,
              scanEntity.isEnabled,
              model.hudStage == .scanning,
              !targetReserve.ready {

            try? await Task.sleep(
                for: .milliseconds(
                    TargetCfg.Preflight.retryMs
                )
            )

            guard targetReserve.canCheck(force: true) else {
                continue
            }

            _ = reserveScanTarget()
        }

        guard targetReserve.ready else {
            return
        }

        finishScanReady()
    }

    @discardableResult
    private func reserveScanTarget() -> Bool {
        guard let scene = anchor.scene else {
            return false
        }

        guard let pose = targetSpawn.pose(
            session: sess.session,
            scene: scene,
            height: TargetCfg.Tree.height
        ) else {
            return false
        }

        targetReserve.reserve(pose)

#if DEBUG
        print(
            String(
                format: "[TARGET PREP] RESERVED x=%.2f y=%.2f z=%.2f",
                pose.pos.x,
                pose.pos.y,
                pose.pos.z
            )
        )
#endif

        return true
    }

    // Resume LiDAR/cursor while finding open floor
    private func resumeOpenScan() {
        guard var comp =
                scanEntity.components[
                    FPScanComp.self
                ] else {
            return
        }

        comp.active = true

        scanEntity.components[
            FPScanComp.self
        ] = comp

        scanEntity.isEnabled = true
    }

    private func finishScanReady() {
        model.msg = ""
        model.scanProgress = 1
        model.scanReady = true

#if DEBUG
        print("[TARGET PREP] SCAN HAS SAFE TARGET")
#endif
    }
}
