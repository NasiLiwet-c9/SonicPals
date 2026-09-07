//
//  FPScanModel.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import Foundation
import RealityKit
import simd

enum FPScanTurn: Equatable {
    case none
    case left
    case right
}

struct FPScanHUD: Equatable {
    let progress: Float
    let turn: FPScanTurn
    let ready: Bool
}

struct FPScanComp: Component {
    var active = false
    var resetID = 0
}

struct FPScanKey: Hashable {
    let x: Int
    let y: Int
    let z: Int

    init(
        _ p: SIMD3<Float>,
        size: Float = 0.08
    ) {
        x = Int(floor(p.x / size))
        y = Int(floor(p.y / size))
        z = Int(floor(p.z / size))
    }
}

extension Notification.Name {
    static let fpScanUpdate = Notification.Name("fpScanUpdate")
}
