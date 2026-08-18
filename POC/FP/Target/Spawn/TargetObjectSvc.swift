//
//  TargetObjectSvc.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import RealityKit
import simd

@MainActor
final class TargetObjectSvc: TargetObjectChecking {
    private let minR: Float
    private let maxR: Float

    init(
        minR: Float = TargetCfg.Clearance.objectMinRadius,
        maxR: Float = TargetCfg.Clearance.objectMaxRadius
    ) {
        self.minR = minR
        self.maxR = maxR
    }

    func blocked(at pos: SIMD3<Float>, height: Float, scene: Scene) -> Bool {
        let radius = min(max(height * 0.44, minR), maxR)

        let heights: [Float] = [
            0.24,
            min(max(height * 0.64, 0.64), 0.86)
        ]

        for y in heights {
            let origin = pos + SIMD3<Float>(0, y, 0)

            for direction in directions {
                if scene.raycast(
                    origin: origin,
                    direction: direction,
                    length: radius,
                    query: .nearest,
                    mask: .sceneUnderstanding,
                    relativeTo: nil
                ).first != nil {
                    return true
                }
            }
        }

        let topRadius = radius * 0.48
        let topHeight = min(max(height - 0.10, 0.76), 1.20)

        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(topRadius, 0, 0),
            SIMD3<Float>(-topRadius, 0, 0),
            SIMD3<Float>(0, 0, topRadius),
            SIMD3<Float>(0, 0, -topRadius)
        ]

        for point in points {
            if scene.raycast(
                origin: pos + point + SIMD3<Float>(0, 0.08, 0),
                direction: SIMD3<Float>(0, 1, 0),
                length: topHeight,
                query: .nearest,
                mask: .sceneUnderstanding,
                relativeTo: nil
            ).first != nil {
                return true
            }
        }

        return false
    }

    private var directions: [SIMD3<Float>] {
        let d: Float = 0.7071

        return [
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(-1, 0, 0),
            SIMD3<Float>(0, 0, 1),
            SIMD3<Float>(0, 0, -1),
            SIMD3<Float>(d, 0, d),
            SIMD3<Float>(-d, 0, d),
            SIMD3<Float>(d, 0, -d),
            SIMD3<Float>(-d, 0, -d)
        ]
    }
}
