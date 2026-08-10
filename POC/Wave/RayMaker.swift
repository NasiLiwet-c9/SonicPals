//
//  RayMaker.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
//

import Foundation
import simd

final class RayMaker {
    private let rings: Int
    private let beamPower: Float

    init(
        rings: Int = 5,
        beamPower: Float = 8
    ) {
        self.rings = max(rings, 0)
        self.beamPower = beamPower
    }

    func make(
        for setting: WaveSetting,
        ringCount: Int? = nil
    ) -> [WaveRay] {
        let total =
            max(
                ringCount ?? rings,
                0
            )

        let hScale =
            tan(
                toRad(
                    setting.hAngleDeg
                )
            )

        let vScale =
            tan(
                toRad(
                    setting.vAngleDeg
                )
            )

        var rays = [
            WaveRay(
                dir: SIMD3<Float>(0, 0, 1),
                power: 1,
                sideDeg: 0
            )
        ]

        guard total > 0 else {
            return rays
        }

        for ring in 1...total {
            let radius =
                Float(ring)
                / Float(total)

            let count = ring * 8

            for index in 0..<count {
                let angle =
                    2
                    * Float.pi
                    * Float(index)
                    / Float(count)

                let x =
                    cos(angle)
                    * hScale
                    * radius

                let y =
                    sin(angle)
                    * vScale
                    * radius

                let dir = simd_normalize(
                    SIMD3<Float>(x, y, 1)
                )

                let offAxis = acos(
                    min(
                        max(dir.z, -1),
                        1
                    )
                )

                let power = pow(
                    max(
                        cos(offAxis),
                        0
                    ),
                    beamPower
                )

                let sideDeg =
                    atan2(
                        dir.x,
                        dir.z
                    )
                    * 180
                    / Float.pi

                rays.append(
                    WaveRay(
                        dir: dir,
                        power: power,
                        sideDeg: sideDeg
                    )
                )
            }
        }

        return rays
    }

    private func toRad(_ degrees: Float) -> Float {
        degrees * Float.pi / 180
    }
}
