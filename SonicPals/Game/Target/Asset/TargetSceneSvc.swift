//
//  TargetSceneSvc.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import RealityKit
import UIKit
import simd

@MainActor
struct TargetSceneSvc {
    let treeH: Float

    func place(_ scene: Entity) -> SIMD3<Float>? {
        let b = scene.visualBounds(
            recursive: true,
            relativeTo: scene,
            excludeInactive: false
        )

        guard b.extents.y > 0.001 else {
            return nil
        }

        let s = treeH / b.extents.y
        let size = b.extents * s
        let center = b.center * s

        scene.scale = SIMD3<Float>(repeating: s)

        scene.position = SIMD3<Float>(
            -center.x,
            (size.y * 0.5) - center.y,
            -center.z
        )

        return size
    }

    func freeze(_ root: Entity) {
        root.stopAllAnimations(recursive: true)
    }

    func muteParticles(_ root: Entity) {
        if var emitter = root.components[ParticleEmitterComponent.self] {
            emitter.isEmitting = false
            root.components[ParticleEmitterComponent.self] = emitter
        }

        for child in root.children {
            muteParticles(child)
        }
    }

    func noShadow(_ root: Entity) {
        root.components.set(GroundingShadowComponent(castsShadow: false))

        for child in root.children {
            noShadow(child)
        }
    }

    func dim(_ root: Entity, factor: Float) {
        if var model = root.components[ModelComponent.self] {
            model.materials = model.materials.map { mat in
                guard var pbr = mat as? PhysicallyBasedMaterial else {
                    return mat
                }

                pbr.baseColor.tint = dimColor(pbr.baseColor.tint, factor: factor)

                return pbr
            }

            root.components[ModelComponent.self] = model
        }

        for child in root.children {
            dim(child, factor: factor)
        }
    }

    private func dimColor(
        _ color: UIColor,
        factor: Float
    ) -> UIColor {
        let f = CGFloat(min(max(factor, 0), 1))

        var r: CGFloat = 1
        var g: CGFloat = 1
        var b: CGFloat = 1
        var a: CGFloat = 1

        if color.getRed(
            &r,
            green: &g,
            blue: &b,
            alpha: &a
        ) {
            return UIColor(
                red: r * f,
                green: g * f,
                blue: b * f,
                alpha: a
            )
        }

        var w: CGFloat = 1

        if color.getWhite(&w, alpha: &a) {
            return UIColor(white: w * f, alpha: a)
        }

        return color
    }
}
