//
//  FPStyle.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
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
                red: 1.00,
                green: 0.25,
                blue: 0.25,
                alpha: 1
            )
            bandA = 1.00

        case .near:
            color = UIColor(
                red: 1.00,
                green: 0.58,
                blue: 0.22,
                alpha: 1
            )
            bandA = 0.92

        case .mid:
            color = UIColor(
                red: 0.73,
                green: 0.43,
                blue: 1.00,
                alpha: 1
            )
            bandA = 0.78

        case .far:
            color = UIColor(
                red: 0.34,
                green: 0.70,
                blue: 1.00,
                alpha: 1
            )
            bandA = 0.64
        }

        let zoneA: Float
        let delay: Int64

        switch zone {
        case .edge:
            zoneA = 0.24
            delay = 0

        case .soft:
            zoneA = 0.58
            delay = 35

        case .core:
            zoneA = 1.00
            delay = 70
        }

        return FPStyle(
            color: color,
            wireA: bandA * zoneA,
            fillA: 0.14 * bandA * zoneA,
            delayMs: delay
        )
    }
}
