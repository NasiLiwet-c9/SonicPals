//
//  ECSWorld+Target.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import Foundation
import RealityKit

extension ECSWorld {
    func spawnTarget() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            _ = await spawnTargetNow(showError: true)
        }
    }

    func scanTarget(with data: WaveData, in scene: Scene) {
        guard let targetEntity,
              var comp = targetEntity.components[TargetComp.self] else {
            return
        }

        let hits = targetWave.hitParts(
            target: targetEntity,
            comp: comp,
            data: data,
            in: scene
        )

        guard !hits.isEmpty else { return }

        let now = Date().timeIntervalSinceReferenceDate

        guard !comp.found else {
            targetEntity.components[TargetComp.self] = comp
            return
        }

        let treeHits = hits.filter { !comp.parts[$0].isMango }

        for index in treeHits where comp.parts.indices.contains(index) {
            comp.seenParts.insert(index)
            comp.pulseUntil[index] = now + 1.25
            comp.parts[index].pulse.isEnabled = true
            comp.parts[index].trace.isEnabled = true
        }

        targetEntity.components[TargetComp.self] = comp
    }

    func eatMango() {
        guard let mango = eatCandidate else { return }

        mango.removeFromParent()
        model.mangoEatenCount += 1
        model.mangoEatReady = false

        eatCandidate = nil
        targetEntity?.removeFromParent()
        targetEntity = nil

        model.hasTarget = false
        model.targetFound = false
        setMsg("")

        advanceMission()
    }
}
