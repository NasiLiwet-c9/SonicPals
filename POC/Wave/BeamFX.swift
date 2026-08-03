//
//  BeamFX.swift
//  POC
//
//  Created by Shanon Newcastle on 03/08/26.
//

import Foundation
import RealityKit
import UIKit
import simd

/// Purely visual "third person" beam effect.
/// Spawns three short parallel beam segments that travel forward from
/// the sensor like projectiles, each performing its own raycast against
/// the LiDAR scene-understanding mesh. On collision each beam spawns a
/// single reflected beam using the real LiDAR surface normal, then that
/// reflected beam fades out and is removed. Never reflects more than once.
///
/// This makes its own raycast call, entirely separate from WaveSim's.
/// It never reads WaveSim/EchoCalc state and never writes anywhere they
/// read from, so it cannot influence the ultrasonic simulation.
@MainActor
final class BeamFX: BeamEffecting {
    private let shape: WaveShape

    /// Small (right, up) offsets from the sensor's forward axis so the
    /// three beams are visually distinguishable while staying parallel.
    private let beamOffsets: [(right: Float, up: Float)] = [
        (-0.028, -0.016),
        (0.028, -0.016),
        (0, 0.024)
    ]

    private let beamLength: Float = 0.05
    private let beamRadius: Float = 0.004
    private let beamSpeed: Float = 0.2
    private let maxDistance: Float = 5
    private let missTravelDistance: Float = 1.2
    private let reflectTravelDistance: Float = 0.35
    private let fadeDuration: TimeInterval = 0.15
    private let color: UIColor = .systemCyan

    // Same pattern as PulseFX: the fade animation is identical every
    // time, so it's generated once and reused rather than regenerated
    // per beam.
    private lazy var fadeResource: AnimationResource? = {
        let fade = FromToByAnimation<Float>(
            from: 1,
            to: 0,
            duration: fadeDuration,
            bindTarget: .opacity
        )

        return try? AnimationResource.generate(
            with: fade
        )
    }()

    init(shape: WaveShape) {
        self.shape = shape
    }

    func emit(
        from start: WaveStart,
        into root: Entity,
        in view: ARView
    ) {
        for offset in beamOffsets {
            let origin =
            start.pos
            + (start.right * offset.right)
            + (start.up * offset.up)

            spawnBeam(
                origin: origin,
                dir: start.forward,
                into: root,
                in: view
            )
        }
    }

    private func spawnBeam(
        origin: SIMD3<Float>,
        dir: SIMD3<Float>,
        into root: Entity,
        in view: ARView
    ) {
        let hit = firstHit(
            in: view,
            start: origin,
            dir: dir
        )

        let distance =
        hit?.distance
        ?? missTravelDistance

        let bolt = makeBolt(
            at: origin,
            dir: dir
        )

        root.addChild(bolt)

        travel(
            bolt,
            from: origin,
            dir: dir,
            distance: distance,
            relativeTo: root
        ) { [weak self] in
            guard let self else {
                return
            }

            guard let hit else {
                self.fadeAndRemove(bolt)
                return
            }

            bolt.removeFromParent()

            self.spawnReflection(
                at: hit.position,
                normal: hit.normal,
                incomingDir: dir,
                into: root
            )
        }
    }

    /// Reflection uses the real LiDAR-mesh surface normal from the
    /// raycast hit — never estimated from the placed object's transform.
    private func spawnReflection(
        at point: SIMD3<Float>,
        normal: SIMD3<Float>,
        incomingDir: SIMD3<Float>,
        into root: Entity
    ) {
        var n = simd_normalize(normal)

        if simd_dot(incomingDir, n) > 0 {
            n = -n
        }

        let reflectDir = simd_normalize(
            incomingDir
            - (
                2
                * simd_dot(incomingDir, n)
                * n
            )
        )

        let bolt = makeBolt(
            at: point,
            dir: reflectDir
        )

        root.addChild(bolt)

        travel(
            bolt,
            from: point,
            dir: reflectDir,
            distance: reflectTravelDistance,
            relativeTo: root
        ) { [weak self] in
            self?.fadeAndRemove(bolt)
        }
    }

    private func makeBolt(
        at origin: SIMD3<Float>,
        dir: SIMD3<Float>
    ) -> ModelEntity {
        // Reuses WaveShape's cached unit-cylinder mesh and cached
        // material — no new MeshResource/SimpleMaterial per beam.
        shape.line(
            from: origin,
            to: origin + (dir * beamLength),
            radius: beamRadius,
            color: color,
            alpha: 1
        )
    }

    private func travel(
        _ bolt: ModelEntity,
        from origin: SIMD3<Float>,
        dir: SIMD3<Float>,
        distance: Float,
        relativeTo root: Entity,
        completion: @escaping () -> Void
    ) {
        let travelDistance =
        max(
            distance - (beamLength / 2),
            0
        )

        let targetMidpoint =
        origin
        + (dir * travelDistance)

        let end = Transform(
            scale: bolt.scale,
            rotation: bolt.orientation,
            translation: targetMidpoint
        )

        let duration = TimeInterval(
            max(distance, 0.01) / beamSpeed
        )

        bolt.move(
            to: end,
            relativeTo: root,
            duration: duration,
            timingFunction: .linear
        )

        Task { [weak bolt] in
            try? await Task.sleep(
                nanoseconds: UInt64(
                    duration * 1_000_000_000
                )
            )

            guard bolt != nil else {
                return
            }

            completion()
        }
    }

    private func fadeAndRemove(_ bolt: ModelEntity) {
        guard let resource = fadeResource else {
            bolt.removeFromParent()
            return
        }

        bolt.components.set(
            OpacityComponent(opacity: 1)
        )

        bolt.playAnimation(resource)

        Task { [weak bolt] in
            try? await Task.sleep(
                nanoseconds: UInt64(
                    fadeDuration * 1_000_000_000
                )
            )

            bolt?.removeFromParent()
        }
    }

    private func firstHit(
        in view: ARView,
        start: SIMD3<Float>,
        dir: SIMD3<Float>
    ) -> CollisionCastHit? {
        view.scene.raycast(
            origin: start,
            direction: dir,
            length: maxDistance,
            query: .nearest,
            mask: .sceneUnderstanding,
            relativeTo: nil
        )
        .first
    }
}
