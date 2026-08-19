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
            totalAlpha: TargetCfg.Echo.mangoPulseAlpha,
            behindAlpha: TargetCfg.Echo.mangoPulseBehindAlpha,
            fill: true,
            scale: TargetCfg.Echo.mangoPulseScale
        )

        setMango(
            on: trace,
            totalAlpha: TargetCfg.Echo.mangoTraceAlpha,
            behindAlpha: TargetCfg.Echo.mangoTraceBehindAlpha,
            fill: false,
            scale: TargetCfg.Echo.mangoTraceScale
        )

        // Sonar above full-color target.
        RealityShade.keepBright(
            pulse,
            order: 2
        )

        RealityShade.keepBright(
            trace,
            order: 2
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
        totalAlpha: Float,
        behindAlpha: Float,
        fill: Bool,
        scale: Float
    ) {
        if entity.name == "MangoTarget" {
            entity.scale *= SIMD3<Float>(repeating: scale)

            let frontAlpha = frontAlpha(
                total: totalAlpha,
                behind: behindAlpha
            )

            setMangoModels(
                on: entity,
                frontAlpha: frontAlpha,
                behindAlpha: behindAlpha,
                fill: fill
            )

            return
        }

        for child in entity.children {
            setMango(
                on: child,
                totalAlpha: totalAlpha,
                behindAlpha: behindAlpha,
                fill: fill,
                scale: scale
            )
        }
    }

    private func setMangoModels(
        on entity: Entity,
        frontAlpha: Float,
        behindAlpha: Float,
        fill: Bool
    ) {
        let children = Array(entity.children)

        if var model = entity.components[ModelComponent.self] {
            let count = max(model.materials.count, 1)

            let front = mangoMat(
                alpha: frontAlpha,
                fill: fill,
                readsDepth: true
            )

            model.materials = (0..<count).map { _ in front }
            entity.components[ModelComponent.self] = model

            let xray = entity.clone(recursive: false)
            xray.name = "MangoXRay"
            xray.transform = .identity

            xray.scale = SIMD3<Float>(
                repeating: TargetCfg.Echo.mangoXrayScale
            )

            if var xrayModel = xray.components[ModelComponent.self] {
                let xrayCount = max(xrayModel.materials.count, 1)

                let behind = mangoMat(
                    alpha: behindAlpha,
                    fill: fill,
                    readsDepth: false
                )

                xrayModel.materials = (0..<xrayCount).map { _ in behind }
                xray.components[ModelComponent.self] = xrayModel
            }

            entity.addChild(xray)
        }

        for child in children {
            setMangoModels(
                on: child,
                frontAlpha: frontAlpha,
                behindAlpha: behindAlpha,
                fill: fill
            )
        }
    }

    private func frontAlpha(
        total: Float,
        behind: Float
    ) -> Float {
        let total = min(max(total, 0), 1)
        let behind = min(max(behind, 0), 0.99)

        return min(
            max(
                1 - ((1 - total) / (1 - behind)),
                0
            ),
            1
        )
    }

    private func echoMat(
        alpha: Float
    ) -> UnlitMaterial {
        var mat = UnlitMaterial(color: .white)

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
        readsDepth: Bool
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
        mat.readsDepth = readsDepth
        mat.writesDepth = false

        mat.blending = .transparent(
            opacity: .init(
                floatLiteral: min(max(alpha, 0), 1)
            )
        )

        return mat
    }
}
