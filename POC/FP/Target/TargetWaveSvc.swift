//
//  TargetWaveSvc.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
//

import RealityKit
import simd

@MainActor
struct TargetWaveSvc: TargetWaveChecking {
    func hitParts(
        target: Entity,
        comp: TargetComp,
        data: WaveData,
        in view: ARView
    ) -> [Int] {
        let localStart =
            target.convert(
                position:
                    data.start.pos,
                from: nil
            )

        var hits: [Int] = []

        for index in comp.parts.indices {
            let part =
                comp.parts[index]

            let nearM =
                nearestDistance(
                    from: localStart,
                    to: part
                )

            guard nearM
                <= data.maxDistance
            else {
                continue
            }

            let center =
                target.convert(
                    position:
                        part.center,
                    to: nil
                )

            if hitsCone(
                center: center,
                radius: part.radius,
                nearM: nearM,
                data: data,
                in: view
            ) {
                hits.append(index)
            }
        }

        return hits
    }

    private func nearestDistance(
        from point: SIMD3<Float>,
        to part: TargetEchoPart
    ) -> Float {
        let minP =
            part.center - part.half

        let maxP =
            part.center + part.half

        let closest = SIMD3<Float>(
            min(
                max(point.x, minP.x),
                maxP.x
            ),
            min(
                max(point.y, minP.y),
                maxP.y
            ),
            min(
                max(point.z, minP.z),
                maxP.z
            )
        )

        return simd_distance(
            point,
            closest
        )
    }

    private func hitsCone(
        center: SIMD3<Float>,
        radius: Float,
        nearM: Float,
        data: WaveData,
        in view: ARView
    ) -> Bool {
        let delta =
            center - data.start.pos

        let dist =
            simd_length(delta)

        guard dist > 0.001 else {
            return true
        }

        let side =
            simd_dot(
                delta,
                data.start.right
            )

        let up =
            simd_dot(
                delta,
                data.start.up
            )

        let forward =
            simd_dot(
                delta,
                data.start.forward
            )

        guard forward + radius > 0.05 else {
            return false
        }

        let hTan =
            tan(
                data.setting.hAngleDeg
                * Float.pi
                / 180
            )

        let vTan =
            tan(
                data.setting.vAngleDeg
                * Float.pi
                / 180
            )

        let width =
            max(
                (
                    max(forward, 0.05)
                    * hTan
                )
                + radius,
                0.01
            )

        let height =
            max(
                (
                    max(forward, 0.05)
                    * vTan
                )
                + radius,
                0.01
            )

        let x = side / width
        let y = up / height

        guard sqrt(
            (x * x) + (y * y)
        ) <= 1 else {
            return false
        }

        let dir =
            delta / dist

        let hit =
            view.scene.raycast(
                origin: data.start.pos,
                direction: dir,
                length:
                    min(
                        dist,
                        data.maxDistance
                    ),
                query: .nearest,
                mask: .sceneUnderstanding,
                relativeTo: nil
            )
            .first

        if let hit,
           hit.distance < nearM - 0.06 {
            return false
        }

        return true
    }
}
