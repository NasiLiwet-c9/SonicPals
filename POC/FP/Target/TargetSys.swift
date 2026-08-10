//
//  TargetSys.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
//

import Foundation
import RealityKit
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

    private let haptic =
        HapticSvc()

    private let foundM: Float = 0.72
    private let nearStepM: Float = 0.20
    private let dirDeg: Float = 14
    private let dirMaxM: Float = 2.60

    required init(scene: Scene) {}

    func update(
        context: SceneUpdateContext
    ) {
        let now =
            Date().timeIntervalSinceReferenceDate

        for entity in
            context.scene.performQuery(Self.query) {
            guard entity.isEnabled,
                  var comp =
                    entity.components[
                        TargetComp.self
                    ],
                  !comp.found,
                  let view =
                    comp.view.value
            else {
                continue
            }

            fadePulses(
                comp: &comp,
                now: now
            )

            let camM =
                view.cameraTransform.matrix

            let cam = camM.pos3

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

                hideEcho(comp)

                comp.real.isEnabled = true

                haptic.found()

                entity.components[
                    TargetComp.self
                ] = comp

                NotificationCenter.default.post(
                    name: .targetFound,
                    object: entity
                )

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

            entity.components[
                TargetComp.self
            ] = comp
        }
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
                .contains(index)
            else {
                comp.pulseUntil[index] = nil
                continue
            }

            comp.parts[index]
                .pulse
                .isEnabled = false

            comp.pulseUntil[index] = nil
        }
    }

    private func hideEcho(
        _ comp: TargetComp
    ) {
        for part in comp.parts {
            part.pulse.isEnabled = false
            part.trace.isEnabled = false
        }
    }

    private func guideCloser(
        comp: inout TargetComp,
        dist: Float,
        now: TimeInterval
    ) {
        guard let best = comp.bestM else {
            comp.bestM = dist
            return
        }

        guard dist <= best - nearStepM else {
            return
        }

        comp.bestM = dist

        guard now - comp.lastNearAt
            >= 0.45
        else {
            return
        }

        comp.lastNearAt = now

        haptic.closer(
            strong: comp.seen
        )
    }

    private func guideDirection(
        comp: inout TargetComp,
        camM: simd_float4x4,
        cam: SIMD3<Float>,
        target: SIMD3<Float>,
        dist: Float,
        now: TimeInterval
    ) {
        guard
            (
                dist <= dirMaxM
                || comp.seen
            ),
            now - comp.lastDirAt >= 0.90
        else {
            return
        }

        var forward = SIMD3<Float>(
            -camM.columns.2.x,
            0,
            -camM.columns.2.z
        )

        var toTarget = SIMD3<Float>(
            target.x - cam.x,
            0,
            target.z - cam.z
        )

        guard simd_length(forward) > 0.001,
              simd_length(toTarget) > 0.001 else {
            return
        }

        forward =
            simd_normalize(forward)

        toTarget =
            simd_normalize(toTarget)

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
