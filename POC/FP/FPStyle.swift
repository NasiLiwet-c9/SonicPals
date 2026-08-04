//
//  FPStyle.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

import UIKit

struct FPStyle {
    let color: UIColor
    let wireA: Float
    let fillA: Float
    let glowA: Float
    let delayMs: Int64
}

extension FPKey {
    var style: FPStyle {
        let color: UIColor
        let wire: Float
        let fill: Float
        let glow: Float
        
        switch band {
        case .hot:
            color = UIColor(
                red: 1,
                green: 0.10,
                blue: 0.02,
                alpha: 1
            )
            
            wire = 1
            fill = 0.20
            glow = 0.07
            
        case .near:
            color = UIColor(
                red: 1,
                green: 0.24,
                blue: 0.42,
                alpha: 1
            )
            
            wire = 0.92
            fill = 0.15
            glow = 0.055
            
        case .mid:
            color = UIColor(
                red: 0.02,
                green: 0.90,
                blue: 1,
                alpha: 1
            )
            
            wire = 0.68
            fill = 0.09
            glow = 0.035
            
        case .far:
            color = UIColor(
                red: 0.10,
                green: 0.30,
                blue: 1,
                alpha: 1
            )
            
            wire = 0.34
            fill = 0.035
            glow = 0.018
        }
        
        let amount: Float
        let delay: Int64
        
        switch zone {
        case .edge:
            amount = 0.17
            delay = 0
            
        case .soft:
            amount = 0.50
            delay = 45
            
        case .core:
            amount = 1
            delay = 90
        }
        
        return FPStyle(
            color: color,
            wireA: wire * amount,
            fillA: fill * amount,
            glowA: glow * amount,
            delayMs: delay
        )
    }
}
