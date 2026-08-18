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
        Task {
            @MainActor
            [weak self] in

            guard let self else {
                return
            }

            _ =
                await spawnTargetNow(
                    showError: true
                )
        }
    }

    func scanTarget(
        with data: WaveData,
        in scene: Scene
    ) {
        guard let targetEntity,
              var comp =
                targetEntity.components[
                    TargetComp.self
                ] else {
            return
        }

        let hits =
            targetWave.hitParts(
                target: targetEntity,
                comp: comp,
                data: data,
                in: scene
            )

        guard !hits.isEmpty else {
            return
        }

        let usable =
            hits.filter {
                hit in

                guard comp.parts.indices
                    .contains(
                        hit.index
                    ) else {
                    return false
                }

                if comp.found {
                    return comp
                        .parts[
                            hit.index
                        ]
                        .isMango
                }

                return !comp
                    .parts[
                        hit.index
                    ]
                    .isMango
            }

        guard !usable.isEmpty else {
            return
        }

        let now =
            Date()
            .timeIntervalSinceReferenceDate

        let range =
            max(
                data.fpRange,
                0.01
            )

        for hit in usable {
            let ratio =
                min(
                    max(
                        hit.distanceM
                        / range,
                        0
                    ),
                    1
                )

            let revealAt =
                now
                + (
                    TimeInterval(
                        ratio
                    )
                    * TargetCfg
                        .Echo
                        .waveTravelS
                )

            if let current =
                comp.pendingRevealAt[
                    hit.index
                ] {
                comp.pendingRevealAt[
                    hit.index
                ] =
                    min(
                        current,
                        revealAt
                    )
            } else {
                comp.pendingRevealAt[
                    hit.index
                ] =
                    revealAt
            }
        }

        targetEntity.components[
            TargetComp.self
        ] = comp
    }

    func eatMango() {
        guard let mango =
            eatCandidate else {
            return
        }

        mango.removeFromParent()

        model.mangoEatenCount += 1
        model.mangoEatReady = false

        eatCandidate = nil

        targetEntity?
            .removeFromParent()

        targetEntity = nil

        model.hasTarget = false
        model.targetFound = false

        setMsg("")
        
        playEatAnimation()

        advanceMission()
    }
    
    private func playEatAnimation() {
        model.eatAnimationID += 1
        model.eatAnimationVisible = true
    }
}
