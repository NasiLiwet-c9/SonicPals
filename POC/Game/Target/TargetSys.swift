//
//  TargetSys.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import ARKit
import Foundation
import RealityKit
import SonarCore
import simd

@MainActor
final class TargetSys: System {
    static let query =
        EntityQuery(
            where:
                .has(
                    TargetComp.self
                )
        )

    static let sessQuery =
        EntityQuery(
            where:
                .has(
                    SessComp.self
                )
        )

    private let haptic =
        HapticSvc.shared

    private let foundM: Float = 0.72
    private let nearStepM: Float = 0.12
    private let dirDeg: Float = 18
    private let dirMaxM: Float = 3.4
    private let nearCooldown: TimeInterval = 0.35
    private let dirCooldown: TimeInterval = 0.70

    required init(
        scene: Scene
    ) {}

    func update(
        context:
            SceneUpdateContext
    ) {
        guard let sess = sessState(
            in: context.scene
        ) else {
            return
        }

        let camM = sess.camera

        let now =
            Date()
            .timeIntervalSinceReferenceDate

        let cam =
            camM.pos3

        for entity
        in context.scene.performQuery(
            Self.query
        ) {
            guard entity.isEnabled,
                  var comp =
                    entity.components[
                        TargetComp.self
                    ] else {
                continue
            }

            lockPose(
                entity,
                comp: comp
            )

            activateScheduled(
                comp: &comp,
                now: now
            )

            fadePulses(
                comp: &comp,
                now: now
            )

            if comp.found {
                entity.components[
                    TargetComp.self
                ] = comp

                continue
            }

            let target =
                entity.position(
                    relativeTo: nil
                )

            let dist =
                horizontalDistance(
                    cam,
                    target
                )

            if comp.seen,
               dist <= foundM {
                comp.found = true

                showReal(
                    comp: &comp
                )

                haptic.found()

                entity.components[
                    TargetComp.self
                ] = comp

                NotificationCenter
                    .default
                    .post(
                        name:
                            .targetFound,
                        object:
                            entity
                    )

                continue
            }

            guard !sess.teaching else {
                entity.components[
                    TargetComp.self
                ] = comp

                continue
            }

            guideCloser(
                comp: &comp,
                dist: dist,
                now: now
            )

            guideDirection(
                comp: &comp,
                camM: camM,
                cam: cam,
                target: target,
                dist: dist,
                now: now
            )

            cueDistance(
                comp: &comp,
                dist: dist
            )

            entity.components[
                TargetComp.self
            ] = comp
        }
    }

    private func activateScheduled(
        comp: inout TargetComp,
        now: TimeInterval
    ) {
        let due =
            comp.pendingRevealAt
                .filter {
                    now >= $0.value
                }
                .map(\.key)

        for index in due {
            guard comp.parts.indices
                .contains(
                    index
                ) else {
                comp.pendingRevealAt[
                    index
                ] = nil

                continue
            }

            comp.seenParts.insert(
                index
            )

            comp.pulseUntil[
                index
            ] =
                now
                + TargetCfg
                    .Echo
                    .pulseHoldS

            comp.parts[
                index
            ]
            .pulse
            .isEnabled = true

            comp.parts[
                index
            ]
            .trace
            .isEnabled = true

            comp.pendingRevealAt[
                index
            ] = nil
        }
    }

    private func showReal(
        comp: inout TargetComp
    ) {
        comp.pendingRevealAt
            .removeAll()

        comp.pulseUntil
            .removeAll()

        for part in comp.parts {
            part.pulse.isEnabled =
                false

            part.trace.isEnabled =
                false
        }

        comp.real.isEnabled =
            true
    }

    private func lockPose(
        _ entity: Entity,
        comp: TargetComp
    ) {
        entity.setPosition(
            comp.lockPos,
            relativeTo: nil
        )

        entity.setOrientation(
            simd_quatf(
                angle:
                    comp.lockYaw,
                axis:
                    SIMD3<Float>(
                        0,
                        1,
                        0
                    )
            ),
            relativeTo: nil
        )
    }

    private func sessState(
        in scene: Scene
    ) -> (camera: simd_float4x4, teaching: Bool)? {
        for entity
        in scene.performQuery(
            Self.sessQuery
        ) {
            guard let comp =
                entity.components[
                    SessComp.self
                ],
            let frame =
                comp.session
                    .value?
                    .currentFrame else {
                continue
            }

            return (
                frame.camera.transform,
                comp.teaching
            )
        }

        return nil
    }

    private func fadePulses(
        comp: inout TargetComp,
        now: TimeInterval
    ) {
        let expired =
            comp.pulseUntil
                .filter {
                    now >= $0.value
                }
                .map(\.key)

        for index in expired {
            guard comp.parts.indices
                .contains(
                    index
                ) else {
                comp.pulseUntil[
                    index
                ] = nil

                continue
            }

            comp.parts[
                index
            ]
            .pulse
            .isEnabled = false

            comp.pulseUntil[
                index
            ] = nil
        }
    }

    private func guideCloser(
        comp: inout TargetComp,
        dist: Float,
        now: TimeInterval
    ) {
        guard let best =
            comp.bestM else {
            comp.bestM = dist
            return
        }

        guard dist
                <= best - nearStepM else {
            return
        }

        comp.bestM = dist

        guard now
                - comp.lastNearAt
                >= nearCooldown else {
            return
        }

        comp.lastNearAt = now

        haptic.closer(
            strong:
                comp.seen
        )

        markFelt(&comp)
    }

    private func guideDirection(
        comp: inout TargetComp,
        camM: simd_float4x4,
        cam: SIMD3<Float>,
        target: SIMD3<Float>,
        dist: Float,
        now: TimeInterval
    ) {
        guard dist <= dirMaxM,
              now
                - comp.lastDirAt
                >= dirCooldown else {
            return
        }

        var forward =
            SIMD3<Float>(
                -camM.columns.2.x,
                0,
                -camM.columns.2.z
            )

        var toTarget =
            SIMD3<Float>(
                target.x - cam.x,
                0,
                target.z - cam.z
            )

        guard simd_length(
            forward
        ) > 0.001,
        simd_length(
            toTarget
        ) > 0.001 else {
            return
        }

        forward =
            simd_normalize(
                forward
            )

        toTarget =
            simd_normalize(
                toTarget
            )

        let dot =
            min(
                max(
                    simd_dot(
                        forward,
                        toTarget
                    ),
                    -1
                ),
                1
            )

        let deg =
            acos(dot)
            * 180
            / Float.pi

        guard deg <= dirDeg else {
            return
        }

        comp.lastDirAt = now

        haptic.direction()

        markFelt(&comp)
    }

    /// The first buzz unlocks the guide arrow and gives Battiw a line.
    private func markFelt(
        _ comp: inout TargetComp
    ) {
        comp.felt = true

        guard !comp.saidSensed else { return }

        comp.saidSensed = true
        post(.sensed)
    }

    private func cueDistance(
        comp: inout TargetComp,
        dist: Float
    ) {
        guard !comp.saidClose,
              comp.felt || comp.seen,
              dist <= TargetCfg.Cue.closeM else {
            return
        }

        comp.saidClose = true
        post(.close)
    }

    private func post(_ cue: TargetCue) {
        NotificationCenter.default.post(
            name: .targetCue,
            object: cue
        )
    }

    private func horizontalDistance(
        _ a: SIMD3<Float>,
        _ b: SIMD3<Float>
    ) -> Float {
        simd_length(
            SIMD2<Float>(
                a.x - b.x,
                a.z - b.z
            )
        )
    }
}
