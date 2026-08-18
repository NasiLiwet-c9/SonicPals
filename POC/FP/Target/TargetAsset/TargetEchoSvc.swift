//
//  TargetEchoSvc.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import RealityKit
import UIKit
import simd

@MainActor
struct TargetEchoSvc {
    func style(
        pulse: Entity,
        trace: Entity
    ) {
        set(
            on: pulse,
            alpha: TargetCfg.Echo.treePulseAlpha
        )

        set(
            on: trace,
            alpha: TargetCfg.Echo.treeTraceAlpha
        )

        setMango(
            on: pulse,
            alpha: TargetCfg.Echo.mangoPulseAlpha,
            fill: true,
            scale: TargetCfg.Echo.mangoPulseScale,
            throughTree: true
        )

        setMango(
            on: trace,
            alpha: TargetCfg.Echo.mangoTraceAlpha,
            fill: false,
            scale: TargetCfg.Echo.mangoTraceScale,
            throughTree: true
        )
    }

    private func set(
        on entity: Entity,
        alpha: Float
    ) {
        if var model = entity.components[ModelComponent.self] {
            let count = max(model.materials.count, 1)
            let mat = echoMat(alpha: alpha)

            model.materials = (0..<count).map { _ in mat }
            entity.components[ModelComponent.self] = model
        }

        for child in entity.children {
            set(
                on: child,
                alpha: alpha
            )
        }
    }

    private func setMango(
        on entity: Entity,
        alpha: Float,
        fill: Bool,
        scale: Float,
        throughTree: Bool
    ) {
        if entity.name == "MangoTarget" {
            entity.scale *= SIMD3<Float>(repeating: scale)

            setFood(
                on: entity,
                alpha: alpha,
                fill: fill,
                throughTree: throughTree
            )

            return
        }

        for child in entity.children {
            setMango(
                on: child,
                alpha: alpha,
                fill: fill,
                scale: scale,
                throughTree: throughTree
            )
        }
    }

    private func setFood(
        on entity: Entity,
        alpha: Float,
        fill: Bool,
        throughTree: Bool
    ) {
        if var model = entity.components[ModelComponent.self] {
            let count = max(model.materials.count, 1)
            let mat = mangoMat(
                alpha: alpha,
                fill: fill,
                throughTree: throughTree
            )

            model.materials = (0..<count).map { _ in mat }
            entity.components[ModelComponent.self] = model
        }

        for child in entity.children {
            setFood(
                on: child,
                alpha: alpha,
                fill: fill,
                throughTree: throughTree
            )
        }
    }

    private func echoMat(
        alpha: Float
    ) -> UnlitMaterial {
        var mat = UnlitMaterial(
            color: .white
        )

        mat.triangleFillMode = .fill
        mat.faceCulling = .none
        mat.readsDepth = true
        mat.writesDepth = false
        mat.blending = .transparent(
            opacity: .init(
                floatLiteral: min(max(alpha, 0), 1)
            )
        )

        return mat
    }

    private func mangoMat(
        alpha: Float,
        fill: Bool,
        throughTree: Bool
    ) -> UnlitMaterial {
        var mat = UnlitMaterial(
            color: UIColor(
                red: 108 / 255,
                green: 92 / 255,
                blue: 231 / 255,
                alpha: 1
            )
        )

        mat.triangleFillMode = fill ? .fill : .lines
        mat.faceCulling = .none
        mat.readsDepth = !throughTree
        mat.writesDepth = false
        mat.blending = .transparent(
            opacity: .init(
                floatLiteral: min(max(alpha, 0), 1)
            )
        )

        return mat
    }
}
