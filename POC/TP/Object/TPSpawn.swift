//
//  TPSpawn.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//

import RealityKit
import UIKit
import simd

struct TPSpawnPose {
    let position: SIMD3<Float>
    let yaw: Float
}

@MainActor
struct TPSpawn:
    TPSpawning {
    
    private let frontM: Float
    private let downM: Float
    
    init(
        frontM: Float = 0.85,
        downM: Float = 0.18
    ) {
        self.frontM = frontM
        self.downM = downM
    }
    
    func pose(
        in view: ARView
    ) -> TPSpawnPose {
        let matrix =
        view.cameraTransform.matrix
        
        let camera = SIMD3<Float>(
            matrix.columns.3.x,
            matrix.columns.3.y,
            matrix.columns.3.z
        )
        
        let forward = simd_normalize(
            SIMD3<Float>(
                -matrix.columns.2.x,
                 -matrix.columns.2.y,
                 -matrix.columns.2.z
            )
        )
        
        let up = simd_normalize(
            SIMD3<Float>(
                matrix.columns.1.x,
                matrix.columns.1.y,
                matrix.columns.1.z
            )
        )
        
        let position =
        camera
        + (forward * frontM)
        - (up * downM)
        
        return TPSpawnPose(
            position: position,
            yaw: yaw(
                from: forward
            )
        )
    }
    
    func move(
        from start: SIMD3<Float>,
        translation: CGPoint,
        in view: ARView
    ) -> SIMD3<Float> {
        let matrix =
        view.cameraTransform.matrix
        
        let camera = SIMD3<Float>(
            matrix.columns.3.x,
            matrix.columns.3.y,
            matrix.columns.3.z
        )
        
        let right = simd_normalize(
            SIMD3<Float>(
                matrix.columns.0.x,
                matrix.columns.0.y,
                matrix.columns.0.z
            )
        )
        
        let up = simd_normalize(
            SIMD3<Float>(
                matrix.columns.1.x,
                matrix.columns.1.y,
                matrix.columns.1.z
            )
        )
        
        let distance = max(
            simd_distance(
                camera,
                start
            ),
            0.4
        )
        
        let meterPerPoint =
        distance
        * 0.00135
        
        return start
        + (
            right
            * Float(translation.x)
            * meterPerPoint
        )
        - (
            up
            * Float(translation.y)
            * meterPerPoint
        )
    }
    
    private func yaw(
        from forward: SIMD3<Float>
    ) -> Float {
        var flat = SIMD3<Float>(
            forward.x,
            0,
            forward.z
        )
        
        if simd_length(flat) < 0.001 {
            flat = SIMD3<Float>(
                0,
                0,
                -1
            )
        } else {
            flat = simd_normalize(
                flat
            )
        }
        
        return atan2(
            -flat.x,
             -flat.z
        )
    }
}
