//
//  ECSWorld+Target.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import Foundation
import RealityKit
import simd

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

        let mangoMode = comp.found

        let usable = hits.filter { hit in
            guard comp.parts.indices.contains(hit.index) else { return false }

            if mangoMode {
                return comp.parts[hit.index].isMango
            }

            return !comp.parts[hit.index].isMango
        }

        guard !usable.isEmpty else { return }

        let hadCue = hasEcho(in: comp, mango: mangoMode)
        let now = Date().timeIntervalSinceReferenceDate
        let range = max(data.fpRange, 0.01)
        var firstAt: TimeInterval?

        for hit in usable {
            let ratio = min(max(hit.distanceM / range, 0), 1)
            let revealAt = now + TimeInterval(ratio) * TargetCfg.Echo.waveTravelS

            firstAt = min(firstAt ?? revealAt, revealAt)

            if let current = comp.pendingRevealAt[hit.index] {
                comp.pendingRevealAt[hit.index] = min(current, revealAt)
            } else {
                comp.pendingRevealAt[hit.index] = revealAt
            }
        }

        targetEntity.components[TargetComp.self] = comp

        if !hadCue, let firstAt {
            scheduleEchoCue(
                mango: mangoMode,
                delay: max(firstAt - now, 0),
                target: targetEntity
            )
        }
    }

    func eatMango() {
        guard let mango = eatCandidate else { return }

        sfx.eat()

        // Particle FX disabled for stability.
        // let mangoWorldPos = mango.position(relativeTo: nil)
        // playMangoFX(at: mangoWorldPos)

        mango.removeFromParent()

        model.mangoEatenCount += 1
        model.mangoEatReady = false

        eatCandidate = nil

        targetEntity?.removeFromParent()
        targetEntity = nil

        model.hasTarget = false
        model.targetFound = false

        setMsg("")
        playEatAnimation()
        advanceMission()
    }

    private func hasEcho(in comp: TargetComp, mango: Bool) -> Bool {
        let ids = Set(comp.seenParts).union(comp.pendingRevealAt.keys)

        return ids.contains { index in
            guard comp.parts.indices.contains(index) else { return false }
            return comp.parts[index].isMango == mango
        }
    }

    private func scheduleEchoCue(
        mango: Bool,
        delay: TimeInterval,
        target: Entity
    ) {
        Task { @MainActor [weak self, weak target] in
            try? await Task.sleep(for: .seconds(delay))

            guard let self,
                  let target,
                  self.targetEntity === target else {
                return
            }

            if mango {
                sfx.mangoDetect()
            } else {
                sfx.treeDetect()
            }
        }
    }

    private func playEatAnimation() {
        model.eatAnimationID += 1
        model.eatAnimationVisible = true
    }

    /*
    /// Particle FX disabled for stability.
    /// Kept here so it can easily be restored later.
    private func playMangoFX(at worldPos: SIMD3<Float>) {
        guard let fx = targetEntity?.findEntity(named: "MangoFX") else {
#if DEBUG
            print("[MANGO FX] NO \"MangoFX\" ENTITY FOUND UNDER targetEntity")
#endif
            return
        }

        fx.setParent(anchor, preservingWorldTransform: false)
        fx.setPosition(worldPos, relativeTo: nil)
        fx.isEnabled = true

        restartParticles(on: fx)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            fx.removeFromParent()
        }
    }

    private func restartParticles(on entity: Entity) {
        if var emitter = entity.components[ParticleEmitterComponent.self] {
            emitter.isEmitting = true
            emitter.restart()
            entity.components[ParticleEmitterComponent.self] = emitter
        }

        for child in entity.children {
            restartParticles(on: child)
        }
    }
    */
}
