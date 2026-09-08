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
    private let overheadR: Float
    private let overheadPad: Float
    private let overheadBottom: Float

    init(
        minR: Float = TargetCfg.Clearance.objectMinRadius,
        maxR: Float = TargetCfg.Clearance.objectMaxRadius,
        overheadR: Float = TargetCfg.Clearance.overheadRadius,
        overheadPad: Float = TargetCfg.Clearance.overheadStartPadding,
        overheadBottom: Float = TargetCfg.Clearance.overheadBottomClearance
    ) {
        self.minR = minR
        self.maxR = maxR
        self.overheadR = overheadR
        self.overheadPad = overheadPad
        self.overheadBottom = overheadBottom
    }

    func blocked(at pos: SIMD3<Float>, height: Float, scene: Scene) -> Bool {
        if sideBlocked(at: pos, height: height, scene: scene) {
            return true
        }

        if overheadBlocked(at: pos, height: height, scene: scene) {
            return true
        }

        return false
    }

    private func sideBlocked(at pos: SIMD3<Float>, height: Float, scene: Scene) -> Bool {
        let radius = min(max(height * 0.44, minR), maxR)

        let heights: [Float] = [
            0.24,
            min(max(height * 0.64, 0.64), 0.90)
        ]

        for y in heights {
            let origin = pos + SIMD3<Float>(0, y, 0)

            let blocked = directions.contains { direction in
                scene.raycast(
                    origin: origin,
                    direction: direction,
                    length: radius,
                    query: .nearest,
                    mask: .sceneUnderstanding,
                    relativeTo: nil
                ).first != nil
            }

            if blocked {
                return true
            }
        }

        return false
    }

    private func overheadBlocked(at pos: SIMD3<Float>, height: Float, scene: Scene) -> Bool {
        let top = height + overheadPad
        let length = max(top - overheadBottom, 0.10)

        let points = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(overheadR, 0, 0),
            SIMD3<Float>(-overheadR, 0, 0),
            SIMD3<Float>(0, 0, overheadR),
            SIMD3<Float>(0, 0, -overheadR)
        ]

        for point in points {
            let origin = pos + point + SIMD3<Float>(0, top, 0)

            if scene.raycast(
                origin: origin,
                direction: SIMD3<Float>(0, -1, 0),
                length: length,
                query: .nearest,
                mask: .sceneUnderstanding,
                relativeTo: nil
            ).first != nil {
#if DEBUG
                print("[TARGET SPAWN] OVERHEAD REJECT")
#endif
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
