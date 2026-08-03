//
//  SceneCtrl+FP.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

import Foundation
import RealityKit
import simd

extension SceneCtrl {
    func camStart(
        in view: ARView
    ) -> WaveStart {
        let matrix =
        view.cameraTransform.matrix
        
        let forward = simd_normalize(
            SIMD3<Float>(
                -matrix.columns.2.x,
                 -matrix.columns.2.y,
                 -matrix.columns.2.z
            )
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
        
        let camPos = SIMD3<Float>(
            matrix.columns.3.x,
            matrix.columns.3.y,
            matrix.columns.3.z
        )
        
        return WaveStart(
            pos:
                camPos
            + (forward * 0.18)
            - (up * 0.04),
            forward: forward,
            right: right,
            up: up
        )
    }
    
    func showFP(
        _ data: WaveData,
        in view: ARView
    ) {
        let root = Entity()
        
        root.name = "fpVision"
        
        root.addChild(
            fpCone.make(
                from: data
            )
        )
        
        world.addChild(root)
        
        fpRoot = root
        state.hasWave = true
        push()
        
        showFPMsg(data)
        
        startFP(
            data,
            in: view,
            root: root
        )
    }
    
    private func showFPMsg(
        _ data: WaveData
    ) {
        guard let hit =
                data.nearestHit else {
            setMsg(
                "BAT VISION • no surface inside the scan area"
            )
            return
        }
        
        let distance = String(
            format: "%.2f m",
            Double(hit.distanceM)
        )
        
        setMsg(
            "BAT VISION • \(data.setting.mode.title) • mesh at \(distance)"
        )
    }
}
