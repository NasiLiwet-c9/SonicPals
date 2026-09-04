//
//  TargetWallSvc.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import ARKit
import simd

@MainActor
final class TargetWallSvc: TargetWallChecking {
    private let minR: Float
    private let maxR: Float

    init(
        minR: Float = TargetCfg.Clearance.wallMinRadius,
        maxR: Float = TargetCfg.Clearance.wallMaxRadius
    ) {
        self.minR = minR
        self.maxR = maxR
    }

    func blocked(at pos: SIMD3<Float>, height: Float, session: ARSession) -> Bool {
        guard let frame = session.currentFrame else { return true }

        let radius = min(max(height * 0.48, minR), maxR)

        let heights: [Float] = [
            0.24,
            min(max(height * 0.52, 0.54), 0.72),
            min(max(height * 0.82, 0.86), 1.06)
        ]

        let walls = frame.anchors
            .compactMap { $0 as? ARPlaneAnchor }
            .filter { $0.alignment == .vertical }

        for wall in walls {
            for y in heights {
                if intersects(wall, point: pos + SIMD3<Float>(0, y, 0), radius: radius) {
                    return true
                }
            }
        }

        return false
    }

    private func intersects(_ plane: ARPlaneAnchor, point: SIMD3<Float>, radius: Float) -> Bool {
        let inverse = simd_inverse(plane.transform)
        let value = inverse * SIMD4<Float>(point.x, point.y, point.z, 1)
        let local = SIMD3<Float>(value.x, value.y, value.z)
        let delta = local - plane.center

        guard abs(delta.y) <= radius else { return false }

        let angle = -plane.planeExtent.rotationOnYAxis
        let c = cos(angle)
        let s = sin(angle)

        let x = (c * delta.x) + (s * delta.z)
        let z = (-s * delta.x) + (c * delta.z)

        let halfX = plane.planeExtent.width * 0.5
        let halfZ = plane.planeExtent.height * 0.5

        return abs(x) <= halfX + radius && abs(z) <= halfZ + radius
    }
}
