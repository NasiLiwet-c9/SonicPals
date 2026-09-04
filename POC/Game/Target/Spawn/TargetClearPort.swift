//
//  TargetClearPort.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import ARKit
import RealityKit
import simd

@MainActor
protocol TargetSpawnClearing: AnyObject {
    func clear(at pos: SIMD3<Float>, height: Float, session: ARSession, scene: Scene) -> Bool
}

@MainActor
protocol TargetWallChecking: AnyObject {
    func blocked(at pos: SIMD3<Float>, height: Float, session: ARSession) -> Bool
}

@MainActor
protocol TargetObjectChecking: AnyObject {
    func blocked(at pos: SIMD3<Float>, height: Float, scene: Scene) -> Bool
}
