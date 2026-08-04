//
//  FPConeShape.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//

import RealityKit
import UIKit
import simd

@MainActor
final class FPConeShape {
    private let cyl = MeshResource.generateCylinder(
        height: 1,
        radius: 1
    )
    
    private let mat: UnlitMaterial
    
    init() {
        var mat = UnlitMaterial(
            color: .systemCyan
        )
        
        mat.blending = .transparent(
            opacity: .init(
                floatLiteral: 0.78
            )
        )
        
        mat.readsDepth = false
        mat.writesDepth = false
        
        self.mat = mat
    }
    
    func make(
        length: Float,
        radiusX: Float,
        radiusY: Float,
        parts: Int = 18,
        lineRadius: Float = 0.0022
    ) -> Entity {
        let root = Entity()
        let tip = SIMD3<Float>.zero
        let end = SIMD3<Float>(0, 0, -length)
        
        root.addChild(
            ring(
                center: end,
                radiusX: radiusX,
                radiusY: radiusY,
                parts: parts,
                lineRadius: lineRadius
            )
        )
        
        let edge = [
            end + SIMD3<Float>(radiusX, 0, 0),
            end + SIMD3<Float>(-radiusX, 0, 0),
            end + SIMD3<Float>(0, radiusY, 0),
            end + SIMD3<Float>(0, -radiusY, 0)
        ]
        
        for point in edge {
            root.addChild(
                line(
                    from: tip,
                    to: point,
                    radius: lineRadius * 0.75
                )
            )
        }
        
        return root
    }
    
    private func ring(
        center: SIMD3<Float>,
        radiusX: Float,
        radiusY: Float,
        parts: Int,
        lineRadius: Float
    ) -> Entity {
        let root = Entity()
        
        var previous = center + SIMD3<Float>(
            radiusX,
            0,
            0
        )
        
        for index in 1...parts {
            let angle =
            2
            * Float.pi
            * Float(index)
            / Float(parts)
            
            let point = center + SIMD3<Float>(
                cos(angle) * radiusX,
                sin(angle) * radiusY,
                0
            )
            
            root.addChild(
                line(
                    from: previous,
                    to: point,
                    radius: lineRadius
                )
            )
            
            previous = point
        }
        
        return root
    }
    
    private func line(
        from start: SIMD3<Float>,
        to end: SIMD3<Float>,
        radius: Float
    ) -> ModelEntity {
        let vector = end - start
        let rawLength = simd_length(vector)
        let length = max(rawLength, 0.001)
        
        let direction = rawLength > 0.0001
        ? vector / rawLength
        : SIMD3<Float>(0, 1, 0)
        
        let line = ModelEntity(
            mesh: cyl,
            materials: [mat]
        )
        
        line.position = (start + end) / 2
        line.scale = SIMD3<Float>(
            radius,
            length,
            radius
        )
        
        line.orientation = simd_quatf(
            from: SIMD3<Float>(0, 1, 0),
            to: direction
        )
        
        return line
    }
}
