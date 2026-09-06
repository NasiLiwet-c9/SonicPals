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

/// Aims the guide arrow once the player has some sense of the tree —
/// either an echo revealed part of it (`seen`) or a haptic fired
/// (`felt`) — until it is `found`.
///
/// Separate from `TargetSys`, which guides by haptics over the same data.
@MainActor
final class TargetGuideSys: System {
    static let query = EntityQuery(
        where: .has(TargetComp.self)
    )

    static let guideQuery = EntityQuery(
        where: .has(GuideComp.self)
    )

    static let sessQuery = EntityQuery(
        where: .has(SessComp.self)
    )

    required init(scene: Scene) {}

    func update(context: SceneUpdateContext) {
        guard let sess = sessState(in: context.scene),
              !sess.teaching
        else {
            aim(in: context.scene, bearing: nil)
            return
        }

        let camM = sess.camera

        for entity in context.scene.performQuery(Self.query) {
            guard entity.isEnabled,
                  let comp = entity.components[TargetComp.self],
                  comp.seen || comp.felt,
                  !comp.found
            else {
                continue
            }

            guard let bearing = bearing(
                to: entity.position(relativeTo: nil),
                camM: camM
            ) else {
                continue
            }

            aim(in: context.scene, bearing: bearing)
            return
        }

        aim(in: context.scene, bearing: nil)
    }

    /// Drives the entity directly: it turns every frame, so routing
    /// through the model would mean a notification per frame.
    private func aim(in scene: Scene, bearing: Float?) {
        for arrow in scene.performQuery(Self.guideQuery) {
            arrow.findEntity(named: GuideArrow.bodyName)?
                .isEnabled = bearing != nil

            guard let bearing,
                  let anchor = arrow.parent else { continue }

            // Roll is anticlockwise from the camera, so a target on the
            // right needs a negative angle.
            let roll = simd_quatf(
                angle: -bearing,
                axis: SIMD3<Float>(0, 0, 1)
            )

            // Pitch outside the roll: the dial leans away from the
            // viewer, and the arrow turns within it.
            arrow.setOrientation(
                GuideArrow.dialPitch * roll,
                relativeTo: anchor
            )
        }
    }

    /// Signed angle about the up axis, from the camera's heading to the
    /// target. Height is ignored: the player navigates on the floor.
    private func bearing(
        to target: SIMD3<Float>,
        camM: simd_float4x4
    ) -> Float? {
        let cam = camM.pos3

        var forward = heading(camM)

        var toTarget = SIMD3<Float>(
            target.x - cam.x,
            0,
            target.z - cam.z
        )

        guard simd_length(forward) > 0.001,
              simd_length(toTarget) > 0.001
        else {
            return nil
        }

        forward = simd_normalize(forward)
        toTarget = simd_normalize(toTarget)

        let dot = simd_dot(forward, toTarget)

        let cross =
            (forward.x * toTarget.z)
            - (forward.z * toTarget.x)

        return atan2(cross, dot)
    }

    /// Which way the player faces, on the floor plane.
    ///
    /// The camera's forward axis collapses when the phone tilts steeply,
    /// which sent the arrow spinning. Near vertical the camera's up axis
    /// is the one still lying along the floor, so blend toward it.
    private func heading(_ camM: simd_float4x4) -> SIMD3<Float> {
        let forward = SIMD3<Float>(
            -camM.columns.2.x,
            -camM.columns.2.y,
            -camM.columns.2.z
        )

        let flatForward = SIMD3<Float>(forward.x, 0, forward.z)

        let flatUp = SIMD3<Float>(
            camM.columns.1.x,
            0,
            camM.columns.1.z
        )

        let sign: Float = forward.y < 0 ? 1 : -1

        let weight = min(simd_length(flatForward) / 0.35, 1)

        return (flatForward * weight)
            + (flatUp * sign * (1 - weight))
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
