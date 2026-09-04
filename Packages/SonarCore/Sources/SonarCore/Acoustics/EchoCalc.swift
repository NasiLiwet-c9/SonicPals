//
//  EchoCalc.swift
//  SonarCore
//
//  Created by Shan Newcastle on 10/08/26.
//

import Foundation

public final class EchoCalc: Sendable {
    public init() {}

    private let startDb: Float = 110
    private let hearDb: Float = 30
    private let surfaceLossDb: Float = 8
    private let refM: Float = 0.1

    /// Received level in dB for one ray return.
    public func level(
        distanceM: Float,
        rayPower: Float,
        anglePower: Float,
        frequencyKHz: Float
    ) -> Float {
        let distance = max(
            distanceM,
            refM
        )

        let spreadDb =
            40 * logValue(
                distance / refM
            )

        let airDb =
            2
            * airLoss(frequencyKHz)
            * distance

        let rayDb =
            -20
            * logValue(
                max(rayPower, 0.001)
            )

        let angleDb =
            -20
            * logValue(
                max(anglePower, 0.05)
            )

        return startDb
            - spreadDb
            - airDb
            - rayDb
            - angleDb
            - surfaceLossDb
    }

    /// Clears both the hearing floor and the blind zone.
    public func heard(
        levelDb: Float,
        distanceM: Float,
        setting: WaveSetting,
        soundSpeed: Float
    ) -> Bool {
        distanceM >= setting.minRange(
            soundSpeed: soundSpeed
        )
        && levelDb >= hearDb
    }

    public func power(levelDb: Float) -> Float {
        min(
            max(
                (levelDb - 15) / 55,
                0.05
            ),
            1
        )
    }

    private func airLoss(_ frequencyKHz: Float) -> Float {
        let frequency =
            min(
                max(frequencyKHz, 20),
                80
            )

        let amount =
            (frequency - 20) / 60

        return 0.35
            + (amount * 1.65)
    }

    private func logValue(_ value: Float) -> Float {
        Float(
            Foundation.log10(
                Double(value)
            )
        )
    }
}
