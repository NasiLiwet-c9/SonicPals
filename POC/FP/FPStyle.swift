//
//  FPStyle.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import UIKit

struct FPStyle {
    let color: UIColor
    let wireA: Float
    let fillA: Float
    let delayMs: Int64
}

extension FPKey {
    var style: FPStyle {
        let color: UIColor
        let bandA: Float

        switch band {
        case .hot:
            color = UIColor(
                red: 102 / 255,
                green: 0 / 255,
                blue: 34 / 255,
                alpha: 1
            )

            bandA = 1.00

        case .near:
            color = UIColor(
                red: 255 / 255,
                green: 122 / 255,
                blue: 0 / 255,
                alpha: 1
            )

            bandA = 0.98

        case .mid:
            color = UIColor(
                red: 255 / 255,
                green: 230 / 255,
                blue: 0 / 255,
                alpha: 1
            )

            bandA = 0.92

        case .far:
            color = UIColor(
                red: 0 / 255,
                green: 255 / 255,
                blue: 204 / 255,
                alpha: 1
            )

            bandA = 0.90
        }

        let zoneA: Float
        let delay: Int64

        switch zone {
        case .edge:
            zoneA = 0.42
            delay = 0

        case .soft:
            zoneA = 0.72
            delay = 35

        case .core:
            zoneA = 1.00
            delay = 70
        }

        return FPStyle(
            color: color,
            wireA: min(bandA * zoneA * 1.02, 1),
            fillA: min(0.20 * bandA * zoneA, 0.20),
            delayMs: delay
        )
    }
}
