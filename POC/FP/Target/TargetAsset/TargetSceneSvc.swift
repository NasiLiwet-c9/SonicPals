//
//  TargetSceneSvc.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import RealityKit
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
        root.components.set(
            GroundingShadowComponent(castsShadow: false)
        )

        for child in root.children {
            noShadow(child)
        }
    }
}
