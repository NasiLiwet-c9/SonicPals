//
//  ObjectMaker.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Shanon Newcastle on 03/08/26.
//

import RealityKit
import UIKit
import simd

@MainActor
final class ObjectMaker:
    ObjectMaking {
    
    func make()
    -> ObjectPart {
        let root =
        Entity()
        
        root.name =
        "object"
        
        let bodyMat =
        SimpleMaterial(
            color:
                    .lightGray,
            isMetallic:
                false
        )
        
        let waveMat =
        SimpleMaterial(
            color:
                    .systemCyan,
            isMetallic:
                false
        )
        
        let body =
        ModelEntity(
            mesh:
                    .generateBox(
                        size:
                            SIMD3<Float>(
                                0.16,
                                0.10,
                                0.14
                            )
                    ),
            materials: [
                bodyMat
            ]
        )
        
        body.position =
        SIMD3<Float>(
            0,
            0.05,
            0
        )
        
        root.addChild(
            body
        )
        
        let waveStart =
        Entity()
        
        waveStart.name =
        "waveStart"
        
        waveStart.position =
        SIMD3<Float>(
            0,
            0.06,
            -0.085
        )
        
        root.addChild(
            waveStart
        )
        
        let disk =
        ModelEntity(
            mesh:
                    .generateCylinder(
                        height:
                            0.025,
                        radius:
                            0.022
                    ),
            materials: [
                waveMat
            ]
        )
        
        disk.orientation =
        simd_quatf(
            angle:
                Float.pi / 2,
            axis:
                SIMD3<Float>(
                    1,
                    0,
                    0
                )
        )
        
        waveStart.addChild(
            disk
        )
        
        return ObjectPart(
            root: root,
            waveStart: waveStart
        )
    }
}
