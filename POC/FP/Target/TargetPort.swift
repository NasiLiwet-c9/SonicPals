//
//  TargetPort.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
//

import RealityKit
import simd

struct TargetEchoPart {
    let name: String

    let pulse: Entity
    let trace: Entity

    let center: SIMD3<Float>
    let half: SIMD3<Float>
    let radius: Float
}

struct TargetPart {
    let root: Entity
    let real: Entity

    let parts: [TargetEchoPart]

    let height: Float
}

struct TargetPose {
    let pos: SIMD3<Float>
    let yaw: Float
}

@MainActor
protocol TargetMaking: AnyObject {
    var loadError: String? { get }

    func prepare() async -> Bool
    func make() -> TargetPart?
}

@MainActor
protocol TargetSpawning {
    func pose(
        in view: ARView,
        height: Float
    ) -> TargetPose?
}

@MainActor
protocol TargetWaveChecking {
    func hitParts(
        target: Entity,
        comp: TargetComp,
        data: WaveData,
        in view: ARView
    ) -> [Int]
}
