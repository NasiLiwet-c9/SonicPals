//
//  TargetWaveMath.swift
//  POC
//
//  Created by Shan Newcastle on 05/09/26.
//

import SonarCore
import simd

/// Did this ping touch that part of the tree
///
/// Split from `TargetWaveSvc`, which needs a `Scene` for line of sight
enum TargetWaveMath {
    /// Distance to a part's box, 0 inside it. Boxes, not points, since
    /// a ping reaches the near end of a branch first
    static func nearestDistance(
        from point: SIMD3<Float>,
        to part: TargetEchoPart
    ) -> Float {
        let minP = part.center - part.half
        let maxP = part.center + part.half

        let closest = SIMD3<Float>(
            min(max(point.x, minP.x), maxP.x),
            min(max(point.y, minP.y), maxP.y),
            min(max(point.z, minP.z), maxP.z)
        )

        return simd_distance(point, closest)
    }

    /// The beam widens with distance, and the radius widens with it
    static func isInCone(
        center: SIMD3<Float>,
        radius: Float,
        data: WaveData
    ) -> Bool {
        let delta = center - data.start.pos
        let dist = simd_length(delta)

        // Standing inside it counts
        guard dist > 0.001 else { return true }

        let side = simd_dot(delta, data.start.right)
        let up = simd_dot(delta, data.start.up)
        let forward = simd_dot(delta, data.start.forward)

        guard forward + radius > 0.05 else { return false }

        let hTan = tan(data.setting.hAngleDeg * Float.pi / 180)
        let vTan = tan(data.setting.vAngleDeg * Float.pi / 180)

        let width = max((max(forward, 0.05) * hTan) + radius, 0.01)
        let height = max((max(forward, 0.05) * vTan) + radius, 0.01)

        let x = side / width
        let y = up / height

        return sqrt((x * x) + (y * y)) <= 1
    }
}
