//
//  FPRevealSystem.swift
//  POC
//
//  A genuine RealityKit System: it runs every frame, queries for any
//  entity carrying an FPRevealComponent, and advances that entity's
//  reveal/hide sequence by however much time actually passed. This
//  replaces the old async Task + Task.sleep chain (loadFPMesh /
//  revealFP / hideFP / finishFP in SceneCtrl+FPAnim.swift) with plain,
//  cancellation-free, per-frame state machine steps — the textbook
//  RealityKit ECS pattern for time-based visual sequences.
//

import RealityKit
import Foundation

final class FPRevealSystem: System {
    static let query = EntityQuery(where: .has(FPRevealComponent.self))

    private static let zoneHideOrder: [FPZone] = [.core, .soft, .edge]
    private static let meshRetryInterval: TimeInterval = 0.14
    private static let maxMeshAttempts = 3
    private static let emptySceneHoldSeconds: TimeInterval = 1.5
    private static let revealHoldSeconds: TimeInterval = 6
    private static let zoneHideStepSeconds: TimeInterval = 0.12

    required init(scene: Scene) {}

    func update(context: SceneUpdateContext) {
        let now = Date().timeIntervalSinceReferenceDate

        for entity in context.scene.performQuery(Self.query) {
            guard var comp = entity.components[FPRevealComponent.self] else {
                continue
            }

            // The root can be removed out from under us (e.g. the user
            // toggled view mode, or placed the object) — treat that as
            // "abandoned" and clean up rather than animating a detached
            // hierarchy.
            guard comp.root.parent != nil else {
                finish(entity: entity, comp: comp)
                continue
            }

            switch comp.stage {
            case let .waitingForMesh(attempt, nextTryAt):
                advanceWaitingForMesh(
                    comp: &comp,
                    attempt: attempt,
                    nextTryAt: nextTryAt,
                    now: now
                )

            case let .revealing(index, startedAt):
                advanceRevealing(
                    comp: &comp,
                    index: index,
                    startedAt: startedAt,
                    now: now
                )

            case let .holding(until):
                if now >= until {
                    comp.stage = .hiding(zoneIndex: 0, lastStepAt: now)
                }

            case let .hiding(zoneIndex, lastStepAt):
                advanceHiding(
                    entity: entity,
                    comp: &comp,
                    zoneIndex: zoneIndex,
                    lastStepAt: lastStepAt,
                    now: now
                )

            case let .empty(until):
                if now >= until {
                    comp.root.removeFromParent()
                    finish(entity: entity, comp: comp)
                    continue
                }
            }

            // `finish` may already have removed the component (root
            // detached, or the hide sequence completed) — don't
            // resurrect it by writing the stale local copy back.
            if entity.components.has(FPRevealComponent.self) {
                entity.components[FPRevealComponent.self] = comp
            }
        }
    }

    private func advanceWaitingForMesh(
        comp: inout FPRevealComponent,
        attempt: Int,
        nextTryAt: TimeInterval,
        now: TimeInterval
    ) {
        guard now >= nextTryAt else {
            return
        }

        let layers = comp.fpMesh.make(in: comp.view, from: comp.data)

        if !layers.isEmpty {
            for layer in layers {
                layer.root.isEnabled = false
                comp.root.addChild(layer.root)
            }

            comp.layers = layers.sorted { $0.delayMs < $1.delayMs }
            comp.stage = .revealing(index: 0, startedAt: now)
            return
        }

        if attempt >= Self.maxMeshAttempts {
            comp.stage = .empty(until: now + Self.emptySceneHoldSeconds)
            return
        }

        comp.stage = .waitingForMesh(
            attempt: attempt + 1,
            nextTryAt: now + Self.meshRetryInterval
        )
    }

    private func advanceRevealing(
        comp: inout FPRevealComponent,
        index: Int,
        startedAt: TimeInterval,
        now: TimeInterval
    ) {
        let elapsedMs = Int64((now - startedAt) * 1_000)
        var index = index

        while index < comp.layers.count,
              comp.layers[index].delayMs <= elapsedMs {
            comp.layers[index].root.isEnabled = true
            index += 1
        }

        comp.stage = index >= comp.layers.count
            ? .holding(until: now + Self.revealHoldSeconds)
            : .revealing(index: index, startedAt: startedAt)
    }

    private func advanceHiding(
        entity: Entity,
        comp: inout FPRevealComponent,
        zoneIndex: Int,
        lastStepAt: TimeInterval,
        now: TimeInterval
    ) {
        guard now - lastStepAt >= Self.zoneHideStepSeconds else {
            return
        }

        guard zoneIndex < Self.zoneHideOrder.count else {
            comp.root.removeFromParent()
            finish(entity: entity, comp: comp)
            return
        }

        let zone = Self.zoneHideOrder[zoneIndex]

        for layer in comp.layers where layer.zone == zone {
            layer.root.isEnabled = false
        }

        comp.stage = .hiding(zoneIndex: zoneIndex + 1, lastStepAt: now)
    }

    private func finish(entity: Entity, comp: FPRevealComponent) {
        comp.onFinished?()
        entity.components.remove(FPRevealComponent.self)
    }
}
