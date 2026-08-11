//
//  FPRevealSys.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import ARKit
import Foundation
import RealityKit

@MainActor
final class FPRevealSys: System {
    static let query = EntityQuery(
        where: .has(RevealComp.self)
    )

    static let sessQuery = EntityQuery(
        where: .has(SessComp.self)
    )

    private let mesh: any FPMeshBuilding

    private let fadeOrder: [FPZone] = [
        .core,
        .soft,
        .edge
    ]

    private let retryS: TimeInterval = 0.10
    private let maxAttempts = 3
    private let emptyS: TimeInterval = 0.8
    private let holdS: TimeInterval = 1.5
    private let fadeStepS: TimeInterval = 0.10

    required init(scene: Scene) {
        mesh = FPMeshBuild(
            read: FPMeshRead(),
            pack: FPMeshPack(liftM: 0.018),
            fact: FPMeshFact()
        )
    }

    func update(
        context: SceneUpdateContext
    ) {
        let now = Date().timeIntervalSinceReferenceDate
        let session = session(in: context.scene)

        for entity in context.scene.performQuery(Self.query) {
            guard var comp = entity.components[RevealComp.self] else {
                continue
            }

            switch comp.stage {
            case let .waiting(attempt, nextAt):
                wait(
                    entity: entity,
                    comp: &comp,
                    session: session,
                    attempt: attempt,
                    nextAt: nextAt,
                    now: now
                )

            case let .revealing(index, startedAt):
                reveal(
                    comp: &comp,
                    index: index,
                    startedAt: startedAt,
                    now: now
                )

            case let .holding(until):
                if now >= until {
                    comp.stage = .fading(
                        zoneIndex: 0,
                        lastAt: now
                    )
                }

            case let .fading(zoneIndex, lastAt):
                fade(
                    entity: entity,
                    comp: &comp,
                    zoneIndex: zoneIndex,
                    lastAt: lastAt,
                    now: now
                )

            case let .empty(until):
                if now >= until {
                    entity.removeFromParent()
                    continue
                }
            }

            if entity.components.has(RevealComp.self) {
                entity.components[RevealComp.self] = comp
            }
        }
    }

    private func session(
        in scene: Scene
    ) -> ARSession? {
        for entity in scene.performQuery(Self.sessQuery) {
            guard let comp = entity.components[SessComp.self] else {
                continue
            }

            return comp.session.value
        }

        return nil
    }

    private func wait(
        entity: Entity,
        comp: inout RevealComp,
        session: ARSession?,
        attempt: Int,
        nextAt: TimeInterval,
        now: TimeInterval
    ) {
        guard now >= nextAt,
              let session
        else {
            return
        }

        let layers = mesh.make(
            session: session,
            from: comp.data
        )

        if !layers.isEmpty {
            for layer in layers {
                layer.root.isEnabled = false
                layer.pulse.isEnabled = true
                layer.trace.isEnabled = false
                entity.addChild(layer.root)
            }

            comp.layers = layers.sorted {
                $0.delayMs < $1.delayMs
            }

            comp.stage = .revealing(
                index: 0,
                startedAt: now
            )

            return
        }

        if attempt >= maxAttempts {
            comp.stage = .empty(
                until: now + emptyS
            )

            return
        }

        comp.stage = .waiting(
            attempt: attempt + 1,
            nextAt: now + retryS
        )
    }

    private func reveal(
        comp: inout RevealComp,
        index: Int,
        startedAt: TimeInterval,
        now: TimeInterval
    ) {
        let elapsed = Int64(
            (now - startedAt) * 1_000
        )

        var next = index

        while next < comp.layers.count,
              comp.layers[next].delayMs <= elapsed {
            comp.layers[next].root.isEnabled = true
            next += 1
        }

        if next >= comp.layers.count {
            comp.stage = .holding(
                until: now + holdS
            )
        } else {
            comp.stage = .revealing(
                index: next,
                startedAt: startedAt
            )
        }
    }

    private func fade(
        entity: Entity,
        comp: inout RevealComp,
        zoneIndex: Int,
        lastAt: TimeInterval,
        now: TimeInterval
    ) {
        guard now - lastAt >= fadeStepS else {
            return
        }

        guard zoneIndex < fadeOrder.count else {
            entity.components[TraceComp.self] = TraceComp(
                createdAt: now
            )

            entity.components.remove(RevealComp.self)
            return
        }

        let zone = fadeOrder[zoneIndex]

        for layer in comp.layers
        where layer.zone == zone {
            layer.pulse.isEnabled = false
            layer.trace.isEnabled = true
            layer.root.isEnabled = true
        }

        comp.stage = .fading(
            zoneIndex: zoneIndex + 1,
            lastAt: now
        )
    }
}
