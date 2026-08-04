//
//  SceneCtrl+Object.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

import RealityKit
import UIKit
import simd

extension SceneCtrl {
    func place() {
        guard state.viewMode == .third else {
            setMsg(
                "Switch to THIRD POV before placing the bat"
            )
            return
        }
        
        guard state.lidarOK,
              ar != nil else {
            setMsg(
                "LiDAR not available"
            )
            return
        }
        
        guard !isPlacing else {
            return
        }
        
        isPlacing = true
        
        setMsg(
            "Loading Bat3…"
        )
        
        Task { [weak self] in
            guard let self else {
                return
            }
            
            let ready = await self
                .objectMaker
                .prepare()
            
            guard ready,
                  let part =
                    self.objectMaker.make(),
                  let ar = self.ar else {
                self.isPlacing = false
                
                self.setMsg(
                    self.objectMaker.loadError
                    ?? "Bat3.usdz could not be loaded"
                )
                
                return
            }
            
            self.isPlacing = false
            
            self.spawn(
                part,
                in: ar
            )
        }
    }
    
    func turn(
        _ deg: Float
    ) {
        guard state.viewMode == .third,
              let object else {
            return
        }
        
        clearWave()
        
        yaw +=
        deg
        * Float.pi
        / 180
        
        object.setOrientation(
            simd_quatf(
                angle: yaw,
                axis: SIMD3<Float>(
                    0,
                    1,
                    0
                )
            ),
            relativeTo: nil
        )
        
        setMsg(
            "Bat direction changed"
        )
    }
    
    func clear() {
        clearWave()
        
        object?.removeFromParent()
        
        object = nil
        waveStart = nil
        dragStart = nil
        yaw = 0
        
        state.hasObject = false
        
        setMsg(
            "Bat removed"
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
        
        switch pan.state {
        case .began:
            clearWave()
            
            dragStart =
            object.position(
                relativeTo: nil
            )
            
            pan.setTranslation(
                .zero,
                in: ar
            )
            
        case .changed:
            guard let dragStart else {
                return
            }
            
            let position = tpSpawn.move(
                from: dragStart,
                translation:
                    pan.translation(
                        in: ar
                    ),
                in: ar
            )
            
            object.setPosition(
                position,
                relativeTo: nil
            )
            
        case .ended:
            dragStart = nil
            
            setMsg(
                "Bat moved"
            )
            
        case .cancelled,
                .failed:
            dragStart = nil
            
        default:
            break
        }
    }
    
    private func spawn(
        _ part: ObjectPart,
        in view: ARView
    ) {
        clearWave()
        
        object?.removeFromParent()
        
        let pose = tpSpawn.pose(
            in: view
        )
        
        world.addChild(
            part.root
        )
        
        part.root.setPosition(
            pose.position,
            relativeTo: nil
        )
        
        yaw = pose.yaw
        
        part.root.setOrientation(
            simd_quatf(
                angle: yaw,
                axis: SIMD3<Float>(
                    0,
                    1,
                    0
                )
            ),
            relativeTo: nil
        )
        
        object = part.root
        waveStart = part.waveStart
        
        state.hasObject = true
        
        setMsg(
            "Bat floating in front • tap Place to recenter"
        )
    }
}
