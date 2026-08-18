//
//  ECSWorld+ScanTarget.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import Foundation
import RealityKit

extension ECSWorld {
    func prepScanTarget(progress: Float) {
        guard progress >= TargetCfg.Preflight.startProgress else { return }
        guard !targetReserve.ready else { return }
        guard targetReserve.canCheck() else { return }

        _ = reserveScanTarget()
    }

    func finishScanTarget() async {
        targetReserve.clearPose()

        if targetReserve.canCheck(force: true), reserveScanTarget() {
            finishScanReady()
            return
        }

        model.scanProgress = TargetCfg.Preflight.waitingProgress
        model.scanTurn = .none
        model.msg = "Scan a little more open floor."

#if DEBUG
        print("[TARGET PREP] NO SAFE POSE AT SCAN COMPLETION")
#endif

        while !Task.isCancelled,
              scanEntity.isEnabled,
              model.hudStage == .scanning,
              !targetReserve.ready {
            try? await Task.sleep(for: .milliseconds(TargetCfg.Preflight.retryMs))

            guard targetReserve.canCheck(force: true) else { continue }
            _ = reserveScanTarget()
        }

        guard targetReserve.ready else { return }
        finishScanReady()
    }

    @discardableResult
    private func reserveScanTarget() -> Bool {
        guard let scene = anchor.scene else { return false }

        guard let pose = targetSpawn.pose(
            session: sess.session,
            scene: scene,
            height: TargetCfg.Tree.height
        ) else {
            return false
        }

        targetReserve.reserve(pose)

#if DEBUG
        print(String(
            format: "[TARGET PREP] RESERVED x=%.2f y=%.2f z=%.2f",
            pose.pos.x,
            pose.pos.y,
            pose.pos.z
        ))
#endif

        return true
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
