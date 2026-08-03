//
//  PulseFX.swift
//  POC
//
//  Created by Shanon Newcastle on 03/08/26.
//

import Foundation
import RealityKit
import UIKit
import simd

/// Purely visual "transmit" pulse effect.
/// Plays a short burst of thin expanding rings that travel forward
/// from the sensor's emitter point. Has no effect on, and reads no
/// state from, the ultrasonic simulation (WaveSim / EchoCalc).
@MainActor
final class PulseFX: PulseEffecting {
    private let shape = WaveShape()

    private let pulseCount = 1
    private let spawnGapRange: ClosedRange<Double> = 0.08...0.12

    private let ringParts = 20
    private let ringRadius: Float = 0.03
    private let lineRadius: Float = 0.0015
    private let travelDistance: Float = 0.55
    private let expandScale: Float = 7
    private let duration: TimeInterval = 0.9
    private let color: UIColor = .systemCyan

    // The fade animation (opacity 1 → 0 over `duration`) is identical on
    // every spawn, so it's generated once and reused instead of calling
    // AnimationResource.generate() per pulse.
    private lazy var fadeResource: AnimationResource? = {
        let fade = FromToByAnimation<Float>(
            from: 1,
            to: 0,
            duration: duration,
            bindTarget: .opacity
        )

        return try? AnimationResource.generate(
            with: fade
        )
    }()

    func emit(
        from start: WaveStart,
        into root: Entity
    ) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            for index in 0..<self.pulseCount {
                self.spawnPulse(
                    from: start,
                    into: root
                )

                guard index < self.pulseCount - 1 else {
                    break
                }

                let gap = Double.random(
                    in: self.spawnGapRange
                )

                try? await Task.sleep(
                    nanoseconds: UInt64(
                        gap * 1_000_000_000
                    )
                )
            }
        }
    }

    private func spawnPulse(
        from start: WaveStart,
        into root: Entity
    ) {
        let pulse = Entity()
        pulse.name = "pulse"

        pulse.orientation = simd_quatf(
            from: SIMD3<Float>(0, 0, 1),
            to: start.forward
        )

        pulse.position = start.pos

        let ring = makeRing()
        pulse.addChild(ring)

        root.addChild(pulse)

        let end = Transform(
            scale: SIMD3<Float>(
                repeating: expandScale
            ),
            rotation: pulse.orientation,
            translation:
                start.pos
                + (start.forward * travelDistance)
        )

        pulse.move(
            to: end,
            relativeTo: root,
            duration: duration,
            timingFunction: .linear
        )

        fadeOut(ring)

        Task { [weak pulse] in
            try? await Task.sleep(
                nanoseconds: UInt64(
                    duration * 1_000_000_000
                )
            )

            pulse?.removeFromParent()
        }
    }

    /// Thin ring in the pulse's own local XY plane (local +Z is forward),
    /// so animating the parent's position/scale moves and expands it
    /// straight ahead rather than in all directions.
    private func makeRing() -> Entity {
        let root = Entity()

        var points: [SIMD3<Float>] = []

        for index in 0...ringParts {
            let angle =
            2
            * Float.pi
            * Float(index)
            / Float(ringParts)

            points.append(
                SIMD3<Float>(
                    cos(angle) * ringRadius,
                    sin(angle) * ringRadius,
                    0
                )
            )
        }

        for index in 0..<(points.count - 1) {
            root.addChild(
                shape.line(
                    from: points[index],
                    to: points[index + 1],
                    radius: lineRadius,
                    color: color,
                    alpha: 1
                )
            )
        }

        return root
    }

    private func fadeOut(_ ring: Entity) {
        guard let resource = fadeResource else {
            return
        }

        for segment in ring.children {
            segment.components.set(
                OpacityComponent(opacity: 1)
            )

            segment.playAnimation(resource)
        }
    }
}
