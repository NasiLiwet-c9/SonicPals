//
//  TargetEchoSvc.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import RealityKit
import UIKit

@MainActor
struct TargetEchoSvc {
    func style(
        pulse: Entity,
        trace: Entity
    ) {
        set(
            on: pulse,
            alpha: 0.82
        )

        set(
            on: trace,
            alpha: 0.05
        )

        setMango(
            on: pulse,
            alpha: 1.0
        )

        setMango(
            on: trace,
            alpha: 0.25
        )
    }

    private func set(
        on entity: Entity,
        alpha: Float
    ) {
        if var model = entity.components[
            ModelComponent.self
        ] {
            let count = max(
                model.materials.count,
                1
            )

            let mat = echoMat(
                alpha: alpha
            )

            model.materials = (0..<count).map {
                _ in mat
            }

            entity.components[
                ModelComponent.self
            ] = model
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
        alpha: Float
    ) {
        if entity.name == "MangoTarget" {
            setYellow(
                on: entity,
                alpha: alpha
            )

            return
        }

        for child in entity.children {
            setMango(
                on: child,
                alpha: alpha
            )
        }
    }

    private func setYellow(
        on entity: Entity,
        alpha: Float
    ) {
        if var model = entity.components[
            ModelComponent.self
        ] {
            let count = max(
                model.materials.count,
                1
            )

            let mat = mangoMat(
                alpha: alpha
            )

            model.materials = (0..<count).map {
                _ in mat
            }

            entity.components[
                ModelComponent.self
            ] = model
        }

        for child in entity.children {
            setYellow(
                on: child,
                alpha: alpha
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
                floatLiteral: min(
                    max(
                        alpha,
                        0
                    ),
                    1
                )
            )
        )

        return mat
    }

    private func mangoMat(
        alpha: Float
    ) -> UnlitMaterial {
        var mat = UnlitMaterial(
            color: UIColor(
                red: 1,
                green: 0.9,
                blue: 0.05,
                alpha: 1
            )
        )

        mat.triangleFillMode = .lines
        mat.faceCulling = .none
        mat.readsDepth = true
        mat.writesDepth = false

        mat.blending = .transparent(
            opacity: .init(
                floatLiteral: min(
                    max(
                        alpha,
                        0
                    ),
                    1
                )
            )
        )

        return mat
    }
}
