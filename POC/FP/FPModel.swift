//
//  FPModel.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
//

import RealityKit
import simd

enum FPBand: Int, CaseIterable {
    case hot
    case near
    case mid
    case far
}

enum FPZone: Int, CaseIterable {
    case edge
    case soft
    case core
}

struct FPKey: Hashable {
    let band: FPBand
    let zone: FPZone
}

struct FPMeshLayer {
    let root: Entity
    let pulse: Entity
    let trace: Entity

    let delayMs: Int64
    let zone: FPZone
}

struct FPMeshData {
    var pos: [SIMD3<Float>] = []
    var idx: [UInt32] = []
    var minM: Float?
}

struct FPSample {
    let key: FPKey
    let distanceM: Float
    let fade: Float
}

struct FPTri {
    let a: SIMD3<Float>
    let b: SIMD3<Float>
    let c: SIMD3<Float>

    var center: SIMD3<Float> {
        (a + b + c) / 3
    }

    var points: [SIMD3<Float>] {
        [
            center,
            a,
            b,
            c
        ]
    }
}

struct FPItem {
    let tri: FPTri
    let sample: FPSample
}
