//
//  ECSWorld+TargetSpawn.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import RealityKit
import simd

extension ECSWorld {
    func spawnTargetNow(showError: Bool) async -> Bool {
        if ForceSpawnRuntime.shared.isActive(for: self) {
            return await forceSpawnTargetNow(showError: showError)
        }

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

        guard let part = targetMaker.make() else {
            if showError { setMsg(targetMaker.loadError ?? "Target could not load") }
            return false
        }

        installTarget(part, pose: pose)
        return true
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

        targetEntity?.removeFromParent()
        part.root.stopAllAnimations(recursive: true)

        part.root.components[TargetComp.self] = TargetComp(
            real: part.real,
            parts: part.parts,
            lockPos: pose.pos,
            lockYaw: pose.yaw
        )

        anchor.addChild(part.root)
        part.root.setPosition(pose.pos, relativeTo: nil)

        part.root.setOrientation(
            simd_quatf(angle: pose.yaw, axis: SIMD3<Float>(0, 1, 0)),
            relativeTo: nil
        )

        targetEntity = part.root
        lastTargetPos = pose.pos
        model.hasTarget = true
        model.targetFound = false
        model.mangoEatReady = false
        model.msg = ""

#if DEBUG
        let p = part.root.position(relativeTo: nil)
        print("[TARGET DEBUG] TARGET INSTALLED")
        print("[TARGET DEBUG] x=\(p.x) y=\(p.y) z=\(p.z)")
#endif
    }

    private func distXZ(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        simd_length(SIMD2<Float>(a.x - b.x, a.z - b.z))
    }
}
