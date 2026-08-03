//
//  WaveShape.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 03/08/26.
//

import Foundation
import RealityKit
import UIKit
import simd

@MainActor
final class WaveShape {
    // MARK: - Resource reuse (test fix for HIGH-probability hypothesis)
    //
    // line()/dot() used to call .generateCylinder / .generateSphere with a
    // fresh size on every single call (dozens of calls per Emit press).
    // A unit-sized mesh generated once and reused via Entity.scale produces
    // the same visuals (cylinder height = local Y axis, sphere is
    // uniform), without regenerating MeshResource per shape.
    //
    // Materials only vary by (color, alpha) from a small fixed set, so
    // they're cached the same way instead of being rebuilt every call.
    // The cache is bounded by the number of distinct (color, alpha)
    // combinations actually used (a handful), not by press count.
    private let unitCylinder: MeshResource = .generateCylinder(
        height: 1,
        radius: 1
    )
    
    private let unitSphere: MeshResource = .generateSphere(
        radius: 1
    )
    
    private var materialCache: [String: SimpleMaterial] = [:]
    
    func line(
        from start: SIMD3<Float>,
        to end: SIMD3<Float>,
        radius: Float,
        color: UIColor,
        alpha: Float
    ) -> ModelEntity {
        let vec = end - start
        let rawLen = simd_length(vec)
        let len = max(rawLen, 0.001)
        
        let dir =
        rawLen > 0.0001
        ? vec / rawLen
        : SIMD3<Float>(0, 1, 0)
        
        let line = ModelEntity(
            mesh: unitCylinder,
            materials: [
                material(
                    color: color,
                    alpha: alpha
                )
            ]
        )
        
        line.scale =
        SIMD3<Float>(
            radius,
            len,
            radius
        )
        
        line.position =
        (start + end) / 2
        
        line.orientation = simd_quatf(
            from: SIMD3<Float>(0, 1, 0),
            to: dir
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
            mesh: unitSphere,
            materials: [
                material(
                    color: color,
                    alpha: alpha
                )
            ]
        )
        
        dot.scale =
        SIMD3<Float>(
            repeating: radius
        )
        
        dot.position = point
        
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
            + (
                (end - start)
                * step
            )
            
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
        
        let x =
        right * size
        
        let y =
        up * size
        
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
        
        var points: [SIMD3<Float>] = []
        
        for index in 0...parts {
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
            
            points.append(
                point
            )
        }
        
        for index in 0..<(points.count - 1) {
            root.addChild(
                line(
                    from: points[index],
                    to: points[index + 1],
                    radius: lineRadius,
                    color: color,
                    alpha: alpha
                )
            )
        }
        
        return root
    }
    
    private func material(
        color: UIColor,
        alpha: Float
    ) -> SimpleMaterial {
        let clampedAlpha =
        min(
            max(alpha, 0),
            1
        )
        
        // Round alpha so near-identical values (e.g. ring alphas that
        // differ by fractions of a percent) collapse onto the same
        // cache entry instead of growing the cache unboundedly.
        let key =
        "\(color)-"
        + String(
            format: "%.2f",
            clampedAlpha
        )
        
        if let cached =
            materialCache[key] {
            return cached
        }
        
        let made = SimpleMaterial(
            color: color.withAlphaComponent(
                CGFloat(
                    clampedAlpha
                )
            ),
            isMetallic: false
        )
        
        materialCache[key] = made
        
        return made
    }
}
