//
//  TPPort.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//

import RealityKit
import UIKit
import simd

@MainActor
protocol ObjectMaking: AnyObject {
    var loadError: String? { get }
    
    func prepare() async -> Bool
    func make() -> ObjectPart?
}

@MainActor
protocol TPSpawning {
    func pose(
        in view: ARView
    ) -> TPSpawnPose
    
    func move(
        from start: SIMD3<Float>,
        translation: CGPoint,
        in view: ARView
    ) -> SIMD3<Float>
}
