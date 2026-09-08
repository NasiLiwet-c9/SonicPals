//
//  TargetGuideSys.swift
//  POC
//
//  Created by Shan Newcastle on 04/09/26.
//

import ARKit
import Foundation
import RealityKit
import SonarCore
import simd

/// Aims the guide arrow between `seen`/`felt` and `found`
///
/// Separate from `TargetSys`, which buzzes over the same data
@MainActor
final class TargetGuideSys: System {
    static let query = EntityQuery(where: .has(TargetComp.self))

    static let guideQuery = EntityQuery(where: .has(GuideComp.self))

    static let sessQuery = EntityQuery(where: .has(SessComp.self))

    required init(scene: Scene) {}

    /// Scene-free init, for tests
    init() {}

    func update(context: SceneUpdateContext) {
        let bearing = guideBearing(
            targets: context.scene.performQuery(Self.query),
            sess: sessState(in: context.scene)
        )

        aim(
            arrows: context.scene.performQuery(Self.guideQuery),
            bearing: bearing
        )
    }

    /// Where to point, or `nil` to hide. Needs `seen` or `felt` first,
    /// and stops at `found`
    func guideBearing(
        targets: some Sequence<Entity>,
        sess: (camera: simd_float4x4, teaching: Bool)?
    ) -> Float? {
        guard let sess, !sess.teaching else { return nil }

        for entity in targets {
            guard entity.isEnabled,
                  let comp = entity.components[TargetComp.self],
                  comp.seen || comp.felt,
                  !comp.found
            else {
                continue
            }

            guard let bearing = bearing(
                to: entity.position(relativeTo: nil),
                camM: sess.camera
            ) else {
                continue
            }

            return bearing
        }

        return nil
    }

    /// Direct, not via the model: a notification per frame is waste
    func aim(arrows: some Sequence<Entity>, bearing: Float?) {
        for arrow in arrows {
            arrow.findEntity(named: GuideArrow.bodyName)?
                .isEnabled = bearing != nil

            guard let bearing,
                  let anchor = arrow.parent else { continue }

            // Anticlockwise from the camera, so right is negative
            let roll = simd_quatf(angle: -bearing, axis: SIMD3<Float>(0, 0, 1))

            // Pitch outside the roll, so the arrow turns in the dial
            arrow.setOrientation(
                GuideArrow.dialPitch * roll,
                relativeTo: anchor
            )
        }
    }

    /// Signed angle from the camera's heading. Height is ignored
    func bearing(
        to target: SIMD3<Float>,
        camM: simd_float4x4
    ) -> Float? {
        let cam = camM.pos3

        var forward = heading(camM)

        var toTarget = SIMD3<Float>(target.x - cam.x, 0, target.z - cam.z)

        guard simd_length(forward) > 0.001,
              simd_length(toTarget) > 0.001
        else {
            return nil
        }

        forward = simd_normalize(forward)
        toTarget = simd_normalize(toTarget)

        let dot = simd_dot(forward, toTarget)

        let cross = (forward.x * toTarget.z) - (forward.z * toTarget.x)

        return atan2(cross, dot)
    }

    /// Forward collapses at steep pitch, which sent the arrow spinning,
    /// so blend toward the up axis near vertical
    func heading(_ camM: simd_float4x4) -> SIMD3<Float> {
        let forward = SIMD3<Float>(
            -camM.columns.2.x,
            -camM.columns.2.y,
            -camM.columns.2.z
        )

        let flatForward = SIMD3<Float>(forward.x, 0, forward.z)

        let flatUp = SIMD3<Float>(camM.columns.1.x, 0, camM.columns.1.z)

        let sign: Float = forward.y < 0 ? 1 : -1

        let weight = min(simd_length(flatForward) / 0.35, 1)

        return (flatForward * weight) + (flatUp * sign * (1 - weight))
    }

    private func sessState(
        in scene: Scene
    ) -> (camera: simd_float4x4, teaching: Bool)? {
        for entity in scene.performQuery(Self.sessQuery) {
            guard let comp = entity.components[SessComp.self],
                  let frame = comp.session.value?.currentFrame
            else {
                continue
            }

            return (frame.camera.transform, comp.teaching)
        }

        return nil
    }
}
