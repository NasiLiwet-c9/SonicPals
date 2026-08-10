//
//  TargetAssetSvc.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import Foundation
import RealityKit
import UIKit
import simd

@MainActor
final class TargetAssetSvc: TargetMaking {
    private let treeName: String
    private let mangoName: String

    private let treeH: Float
    private let mangoSpan: Float

    private var treeTpl: Entity?
    private var mangoTpl: Entity?

    private var task:
        Task<(Entity, Entity), Error>?

    private(set)
    var loadError: String?

    init(
        treeName: String = "Stylized_Tree",
        mangoName: String = "Mango",
        treeH: Float = 1.55,
        mangoSpan: Float = 0.14
    ) {
        self.treeName = treeName
        self.mangoName = mangoName
        self.treeH = treeH
        self.mangoSpan = mangoSpan
    }

    func prepare() async -> Bool {
        if treeTpl != nil,
           mangoTpl != nil {
            return true
        }

        if let task {
            return await finish(task)
        }

        guard Bundle.main.url(
            forResource: treeName,
            withExtension: "usdz"
        ) != nil else {
            loadError =
                "\(treeName).usdz is missing"

            return false
        }

        guard Bundle.main.url(
            forResource: mangoName,
            withExtension: "usdz"
        ) != nil else {
            loadError =
                "\(mangoName).usdz is missing"

            return false
        }

        let treeName = treeName
        let mangoName = mangoName

        let newTask =
            Task { @MainActor in
                async let tree =
                    Entity(
                        named: treeName,
                        in: Bundle.main
                    )

                async let mango =
                    Entity(
                        named: mangoName,
                        in: Bundle.main
                    )

                return try await (
                    tree,
                    mango
                )
            }

        task = newTask

        return await finish(newTask)
    }

    func make() -> TargetPart? {
        guard let treeTpl,
              let mangoTpl else {
            loadError =
                "Target assets are not ready"

            return nil
        }

        let real = Entity()
        real.name = "targetReal"

        let tree =
            treeTpl.clone(
                recursive: true
            )

        guard let treeSize =
            placeTree(tree)
        else {
            loadError =
                "Tree bounds are empty"

            return nil
        }

        let mango =
            mangoTpl.clone(
                recursive: true
            )

        guard placeMango(
            mango,
            treeSize: treeSize
        ) else {
            loadError =
                "Mango bounds are empty"

            return nil
        }

        disableGroundShadow(on: tree)
        disableGroundShadow(on: mango)

        real.addChild(tree)
        real.addChild(mango)

        let pulse =
            real.clone(
                recursive: true
            )

        let trace =
            real.clone(
                recursive: true
            )

        setEchoMat(
            on: pulse,
            alpha: 0.82
        )

        setEchoMat(
            on: trace,
            alpha: 0.05
        )

        disableGroundShadow(on: real)
        disableGroundShadow(on: pulse)
        disableGroundShadow(on: trace)

        guard let parts = makeParts(
            pulse: pulse,
            trace: trace
        ),
        !parts.isEmpty else {
            loadError =
                "Target has no renderable parts"

            return nil
        }

        real.isEnabled = false

        for part in parts {
            part.pulse.isEnabled = false
            part.trace.isEnabled = false
        }

        let root = Entity()

        root.name = "target"

        root.addChild(real)
        root.addChild(pulse)
        root.addChild(trace)

        loadError = nil

        return TargetPart(
            root: root,
            real: real,
            parts: parts,
            height: treeSize.y
        )
    }

    private func makeParts(
        pulse: Entity,
        trace: Entity
    ) -> [TargetEchoPart]? {
        let pulseModels =
            modelEntities(in: pulse)

        let traceModels =
            modelEntities(in: trace)

        guard pulseModels.count
            == traceModels.count
        else {
            return nil
        }

        var parts:
            [TargetEchoPart] = []

        parts.reserveCapacity(
            pulseModels.count
        )

        for index in pulseModels.indices {
            let p = pulseModels[index]
            let t = traceModels[index]

            let bounds =
                p.visualBounds(
                    recursive: false,
                    relativeTo: pulse,
                    excludeInactive: false
                )

            guard bounds.extents.x > 0.001
                    || bounds.extents.y > 0.001
                    || bounds.extents.z > 0.001
            else {
                continue
            }

            let radius =
                max(
                    simd_length(
                        bounds.extents
                    )
                    * 0.5,
                    0.04
                )

            let name =
                p.name.trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

            parts.append(
                TargetEchoPart(
                    name:
                        name.isEmpty
                        ? "part\(index)"
                        : name,
                    pulse: p,
                    trace: t,
                    center: bounds.center,
                    half:
                        bounds.extents * 0.5,
                    radius: radius
                )
            )
        }

        return parts
    }

    private func modelEntities(
        in root: Entity
    ) -> [Entity] {
        var result: [Entity] = []

        func walk(_ entity: Entity) {
            if entity.components.has(
                ModelComponent.self
            ) {
                result.append(entity)
            }

            for child in entity.children {
                walk(child)
            }
        }

        walk(root)

        return result
    }

    private func placeTree(
        _ tree: Entity
    ) -> SIMD3<Float>? {
        let bounds =
            tree.visualBounds(
                recursive: true,
                relativeTo: tree,
                excludeInactive: false
            )

        guard bounds.extents.y > 0.001 else {
            return nil
        }

        let scale =
            treeH / bounds.extents.y

        let size =
            bounds.extents * scale

        let center =
            bounds.center * scale

        tree.scale =
            SIMD3<Float>(
                repeating: scale
            )

        tree.position = SIMD3<Float>(
            -center.x,
            (size.y * 0.5) - center.y,
            -center.z
        )

        return size
    }

    private func placeMango(
        _ mango: Entity,
        treeSize: SIMD3<Float>
    ) -> Bool {
        let bounds =
            mango.visualBounds(
                recursive: true,
                relativeTo: mango,
                excludeInactive: false
            )

        let largest =
            max(
                bounds.extents.x,
                max(
                    bounds.extents.y,
                    bounds.extents.z
                )
            )

        guard largest > 0.001 else {
            return false
        }

        let scale =
            mangoSpan / largest

        let center =
            bounds.center * scale

        mango.scale =
            SIMD3<Float>(
                repeating: scale
            )

        mango.position = SIMD3<Float>(
            max(
                treeSize.x * 0.23,
                0.16
            )
            - center.x,

            (treeSize.y * 0.69)
            - center.y,

            max(
                treeSize.z * 0.10,
                0.04
            )
            - center.z
        )

        return true
    }

    private func setEchoMat(
        on entity: Entity,
        alpha: Float
    ) {
        if var model =
            entity.components[
                ModelComponent.self
            ] {
            let count =
                max(
                    model.materials.count,
                    1
                )

            let mat =
                echoMat(
                    alpha: alpha
                )

            model.materials =
                (0..<count).map { _ in
                    mat
                }

            entity.components[
                ModelComponent.self
            ] = model
        }

        for child in entity.children {
            setEchoMat(
                on: child,
                alpha: alpha
            )
        }
    }

    private func disableGroundShadow(
        on entity: Entity
    ) {
        entity.components.set(
            GroundingShadowComponent(
                castsShadow: false
            )
        )

        for child in entity.children {
            disableGroundShadow(
                on: child
            )
        }
    }

    private func echoMat(
        alpha: Float
    ) -> UnlitMaterial {
        var mat = UnlitMaterial(
            color: UIColor(
                red: 0.53,
                green: 0.43,
                blue: 1,
                alpha: 1
            )
        )

        mat.triangleFillMode = .lines
        mat.faceCulling = .none
        mat.readsDepth = true
        mat.writesDepth = false

        mat.blending = .transparent(
            opacity:
                .init(
                    floatLiteral:
                        min(
                            max(alpha, 0),
                            1
                        )
                )
        )

        return mat
    }

    private func finish(
        _ task:
            Task<(Entity, Entity), Error>
    ) async -> Bool {
        do {
            let pair =
                try await task.value

            treeTpl = pair.0
            mangoTpl = pair.1

            self.task = nil
            loadError = nil

            return true
        } catch {
            self.task = nil
            loadError =
                error.localizedDescription

            return false
        }
    }
}
