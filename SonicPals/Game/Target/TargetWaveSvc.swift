//
//  TargetWaveSvc.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import RealityKit
import SonarCore
import simd

@MainActor
struct TargetWaveSvc:
    TargetWaveChecking {
    func hitParts(
        target: Entity,
        comp: TargetComp,
        data: WaveData,
        in scene: Scene
    ) -> [TargetWaveHit] {
        let localStart = target.convert(position: data.start.pos, from: nil)

        var hits: [TargetWaveHit] = []

        for index
        in comp.parts.indices {
            let part = comp.parts[index]

            let nearM = TargetWaveMath.nearestDistance(from: localStart, to: part)

            guard nearM
                    <= data.fpRange else {
                continue
            }

            let center = target.convert(position: part.center, to: nil)

            if hitsCone(
                center: center,
                radius: part.radius,
                nearM: nearM,
                data: data,
                in: scene
            ) {
                hits.append(TargetWaveHit(index: index, distanceM: nearM))
            }
        }

        return hits
    }

    /// The beam test plus a line-of-sight check: something solid in
    /// front of the part means the ping never reached it
    private func hitsCone(
        center: SIMD3<Float>,
        radius: Float,
        nearM: Float,
        data: WaveData,
        in scene: Scene
    ) -> Bool {
        guard TargetWaveMath.isInCone(
            center: center,
            radius: radius,
            data: data
        ) else {
            return false
        }

        let delta = center - data.start.pos
        let dist = simd_length(delta)

        guard dist > 0.001 else { return true }

        let hit = scene.raycast(
            origin: data.start.pos,
            direction: delta / dist,
            length: min(dist, data.fpRange),
            query: .nearest,
            mask: .sceneUnderstanding,
            relativeTo: nil
        )
        .first

        if let hit, hit.distance < nearM - 0.06 {
            return false
        }

        return true
    }
}
