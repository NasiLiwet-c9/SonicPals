//
//  WaveShape.swift
//  POC
//
//  Created by Shanon Newcastle on 03/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

import RealityKit
import UIKit
import simd

@MainActor
final class WaveShape {
    private struct MatKey: Hashable {
        let red: Int
        let green: Int
        let blue: Int
        let alpha: Int
    }
    
    private let cyl = MeshResource.generateCylinder(
        height: 1,
        radius: 1
    )
    
    private let sphere = MeshResource.generateSphere(
        radius: 1
    )
    
    private var mats: [MatKey: SimpleMaterial] = [:]
    
    func line(
        from start: SIMD3<Float>,
        to end: SIMD3<Float>,
        radius: Float,
        color: UIColor,
        alpha: Float
    ) -> ModelEntity {
        let vector = end - start
        let rawLength = simd_length(vector)
        let length = max(rawLength, 0.001)
        
        let direction = rawLength > 0.0001
        ? vector / rawLength
        : SIMD3<Float>(0, 1, 0)
        
        let line = ModelEntity(
            mesh: cyl,
            materials: [
                material(
                    color: color,
                    alpha: alpha
                )
            ]
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
    
    func dot(
        at point: SIMD3<Float>,
        radius: Float,
        color: UIColor,
        alpha: Float
    ) -> ModelEntity {
        let dot = ModelEntity(
            mesh: sphere,
            materials: [
                material(
                    color: color,
                    alpha: alpha
                )
            ]
        )
        
        dot.position = point
        dot.scale = SIMD3<Float>(
            repeating: radius
        )
        
        return dot
    }
    
    func flow(
        from start: SIMD3<Float>,
        to end: SIMD3<Float>,
        count: Int,
        radius: Float,
        color: UIColor
    ) -> Entity {
        let root = Entity()
        
        guard count > 0 else {
            return root
        }
        
        for index in 1...count {
            let step =
            Float(index)
            / Float(count + 1)
            
            let point =
            start
            + ((end - start) * step)
            
            root.addChild(
                dot(
                    at: point,
                    radius: radius,
                    color: color,
                    alpha: 0.95
                )
            )
        }
        
        return root
    }
    
    func cross(
        at point: SIMD3<Float>,
        right: SIMD3<Float>,
        up: SIMD3<Float>,
        size: Float,
        lineRadius: Float,
        color: UIColor
    ) -> Entity {
        let root = Entity()
        let x = right * size
        let y = up * size
        
        root.addChild(
            line(
                from: point - x - y,
                to: point + x + y,
                radius: lineRadius,
                color: color,
                alpha: 1
            )
        )
        
        root.addChild(
            line(
                from: point - x + y,
                to: point + x - y,
                radius: lineRadius,
                color: color,
                alpha: 1
            )
        )
        
        return root
    }
    
    func ring(
        center: SIMD3<Float>,
        right: SIMD3<Float>,
        up: SIMD3<Float>,
        radiusX: Float,
        radiusY: Float,
        parts: Int,
        lineRadius: Float,
        color: UIColor,
        alpha: Float
    ) -> Entity {
        let root = Entity()
        
        guard parts >= 3 else {
            return root
        }
        
        var previous =
        center
        + (right * radiusX)
        
        for index in 1...parts {
            let angle =
            2
            * Float.pi
            * Float(index)
            / Float(parts)
            
            let point =
            center
            + (
                right
                * cos(angle)
                * radiusX
            )
            + (
                up
                * sin(angle)
                * radiusY
            )
            
            root.addChild(
                line(
                    from: previous,
                    to: point,
                    radius: lineRadius,
                    color: color,
                    alpha: alpha
                )
            )
            
            previous = point
        }
        
        return root
    }
    
    private func material(
        color: UIColor,
        alpha: Float
    ) -> SimpleMaterial {
        let safeAlpha = min(
            max(alpha, 0),
            1
        )
        
        let resolved = color.resolvedColor(
            with: UITraitCollection(
                userInterfaceStyle: .dark
            )
        )
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var unusedAlpha: CGFloat = 0
        
        resolved.getRed(
            &red,
            green: &green,
            blue: &blue,
            alpha: &unusedAlpha
        )
        
        let key = MatKey(
            red: Int((red * 255).rounded()),
            green: Int((green * 255).rounded()),
            blue: Int((blue * 255).rounded()),
            alpha: Int((safeAlpha * 100).rounded())
        )
        
        if let cached = mats[key] {
            return cached
        }
        
        let mat = SimpleMaterial(
            color: resolved.withAlphaComponent(
                CGFloat(safeAlpha)
            ),
            isMetallic: false
        )
        
        mats[key] = mat
        return mat
    }
}
