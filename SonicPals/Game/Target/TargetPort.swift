//
//  TargetPort.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import ARKit
import RealityKit
import SonarCore
import simd

struct TargetEchoPart {
    let name: String
    let pulse: Entity
    let trace: Entity
    let center: SIMD3<Float>
    let half: SIMD3<Float>
    let radius: Float
    let isMango: Bool
}

struct TargetWaveHit {
    let index: Int
    let distanceM: Float
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

    /// Builds the next target ahead of time. `make` is several recursive
    /// clones plus a material walk, which visibly stalls the frame if it
    /// runs at the moment of spawning
    func prewarm() async

    func make() -> TargetPart?
}

@MainActor
protocol TargetSpawning {
    func pose(
        session: ARSession,
        scene: Scene,
        height: Float
    ) -> TargetPose?
}

@MainActor
protocol TargetWaveChecking {
    func hitParts(
        target: Entity,
        comp: TargetComp,
        data: WaveData,
        in scene: Scene
    ) -> [TargetWaveHit]
}
