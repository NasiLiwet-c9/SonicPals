//
//  SceneCtrl+Object.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Shanon Newcastle on 03/08/26.
//

import ARKit
import RealityKit
import UIKit
import simd

extension SceneCtrl {
    func place() {
        guard state.viewMode == .third else {
            setMsg(
                "Switch to THIRD POV before placing the object"
            )
            return
        }
        
        guard state.lidarOK,
              let ar else {
            setMsg(
                "LiDAR not available"
            )
            return
        }
        
        let point = CGPoint(
            x: ar.bounds.midX,
            y: ar.bounds.midY
        )
        
        guard let hit =
                placeSvc.hit(
                    in: ar,
                    at: point
                ) else {
            setMsg(
                "Horizontal surface not found"
            )
            return
        }
        
        clearWave()
        
        object?
            .removeFromParent()
        
        let part =
        objectMaker.make()
        
        world.addChild(
            part.root
        )
        
        part.root.setPosition(
            hit.worldTransform.pos3,
            relativeTo: nil
        )
        
        yaw =
        camYaw(
            in: ar
        )
        
        let turn =
        simd_quatf(
            angle: yaw,
            axis: SIMD3<Float>(
                0,
                1,
                0
            )
        )
        
        part.root.setOrientation(
            turn,
            relativeTo: nil
        )
        
        object =
        part.root
        
        waveStart =
        part.waveStart
        
        state.hasObject =
        true
        
        setMsg(
            "Object placed, drag or twist to move it"
        )
    }
    
    func turn(_ deg: Float) {
        guard state.viewMode == .third,
              let object else {
            return
        }
        
        clearWave()
        
        yaw +=
        deg
        * Float.pi
        / 180
        
        let turn =
        simd_quatf(
            angle: yaw,
            axis: SIMD3<Float>(
                0,
                1,
                0
            )
        )
        
        object.setOrientation(
            turn,
            relativeTo: nil
        )
        
        setMsg(
            "Direction changed"
        )
    }
    
    func clear() {
        clearWave()
        
        object?
            .removeFromParent()
        
        object = nil
        waveStart = nil
        yaw = 0
        
        state.hasObject =
        false
        
        setMsg(
            "Object removed"
        )
    }
    
    @objc func drag(
        _ pan: UIPanGestureRecognizer
    ) {
        guard state.viewMode == .third,
              let ar,
              let object else {
            return
        }
        
        guard pan.state == .began
                || pan.state == .changed
                || pan.state == .ended else {
            return
        }
        
        let point =
        pan.location(
            in: ar
        )
        
        guard let hit =
                placeSvc.hit(
                    in: ar,
                    at: point
                ) else {
            return
        }
        
        clearWave()
        
        object.setPosition(
            hit.worldTransform.pos3,
            relativeTo: nil
        )
        
        if pan.state == .ended {
            setMsg(
                "Object moved"
            )
        }
    }
    
    private func camYaw(
        in view: ARView
    ) -> Float {
        let matrix =
        view.cameraTransform.matrix
        
        var forward =
        SIMD3<Float>(
            -matrix.columns.2.x,
             0,
             -matrix.columns.2.z
        )
        
        if simd_length(
            forward
        ) < 0.001 {
            forward =
            SIMD3<Float>(
                0,
                0,
                -1
            )
        } else {
            forward =
            simd_normalize(
                forward
            )
        }
        
        return atan2(
            -forward.x,
             -forward.z
        )
    }
}
