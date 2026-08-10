//
//  FPConeScan.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import simd

struct FPConeScan {
    private let start: WaveStart
    private let range: Float

    private let hTan: Float
    private let vTan: Float

    private let scale: Float = 1.10

    init(data: WaveData) {
        start = data.start

        range = min(
            data.fpRange,
            data.maxDistance
        )

        hTan = max(
            tan(
                data.setting.hAngleDeg
                * Float.pi
                / 180
            )
            * scale,
            0.01
        )

        vTan = max(
            tan(
                data.setting.vAngleDeg
                * Float.pi
                / 180
            )
            * scale,
            0.01
        )
    }

    func contains(
        _ point: SIMD3<Float>,
        pad: Float = 1.08
    ) -> Bool {
        let local = localPos(point)

        guard local.forward > 0.05,
              local.forward <= range else {
            return false
        }

        guard simd_distance(
            point,
            start.pos
        ) <= range else {
            return false
        }

        return amount(
            side: local.side,
            up: local.up,
            forward: local.forward
        ) <= pad
    }

    func intersectsSphere(
        center: SIMD3<Float>,
        radius: Float,
        pad: Float = 1.12
    ) -> Bool {
        let local = localPos(center)
        let radius = max(radius, 0)

        guard local.forward + radius > 0.05,
              local.forward - radius <= range else {
            return false
        }

        let forward =
            min(
                max(
                    local.forward,
                    0.05
                ),
                range
            )

        let width =
            max(
                (
                    forward
                    * hTan
                    * pad
                )
                + radius,
                0.001
            )

        let height =
            max(
                (
                    forward
                    * vTan
                    * pad
                )
                + radius,
                0.001
            )

        let x = local.side / width
        let y = local.up / height

        return sqrt(
            (x * x) + (y * y)
        ) <= 1
    }

    func sample(
        _ point: SIMD3<Float>
    ) -> (
        distanceM: Float,
        fade: Float
    )? {
        let local = localPos(point)

        guard local.forward > 0.05,
              local.forward <= range else {
            return nil
        }

        let coneAmount =
            amount(
                side: local.side,
                up: local.up,
                forward: local.forward
            )

        guard coneAmount <= 1.08 else {
            return nil
        }

        let distance =
            simd_distance(
                point,
                start.pos
            )

        guard distance <= range else {
            return nil
        }

        let fade =
            smoothFade(
                value: coneAmount,
                fullUntil: 0.64,
                zeroAt: 1.08
            )

        return (
            distance,
            fade
        )
    }

    private func localPos(
        _ point: SIMD3<Float>
    ) -> (
        side: Float,
        up: Float,
        forward: Float
    ) {
        let delta = point - start.pos

        return (
            simd_dot(
                delta,
                start.right
            ),
            simd_dot(
                delta,
                start.up
            ),
            simd_dot(
                delta,
                start.forward
            )
        )
    }

    private func amount(
        side: Float,
        up: Float,
        forward: Float
    ) -> Float {
        let width =
            max(
                forward * hTan,
                0.001
            )

        let height =
            max(
                forward * vTan,
                0.001
            )

        let x = side / width
        let y = up / height

        return sqrt(
            (x * x) + (y * y)
        )
    }

    private func smoothFade(
        value: Float,
        fullUntil: Float,
        zeroAt: Float
    ) -> Float {
        if value <= fullUntil {
            return 1
        }

        if value >= zeroAt {
            return 0
        }

        let step =
            (value - fullUntil)
            / (zeroAt - fullUntil)

        let smooth =
            step
            * step
            * (3 - (2 * step))

        return 1 - smooth
    }
}
