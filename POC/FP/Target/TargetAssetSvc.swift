//
//  TargetAssetSvc.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import Foundation
import RealityKit
import RealityKitContent
import UIKit
import simd

@MainActor
final class TargetAssetSvc: TargetMaking {
    private let sceneName: String
    private let treeH: Float

    private var sceneTpl: Entity?

    private var task: Task<Entity, Error>?

    private(set)
    var loadError: String?

    init(
        sceneName: String = "Mango+Tree",
        treeH: Float = 1.55
    ) {
        self.sceneName = sceneName
        self.treeH = treeH
    }

    func prepare() async -> Bool {
        if sceneTpl != nil {
            return true
        }

        if let task {
            return await finish(task)
        }

        let sceneName = sceneName

        let newTask =
            Task { @MainActor in
                try await Entity(
                    named: sceneName,
                    in: realityKitContentBundle
                )
            }

        task = newTask

        return await finish(newTask)
    }

    func make() -> TargetPart? {
        guard let sceneTpl else {
            loadError =
                "Target assets are not ready"

            return nil
        }

        let real =
            sceneTpl.clone(
                recursive: true
            )

        real.name = "targetReal"

        guard let treeSize =
            placeScene(real)
        else {
            loadError =
                "Scene bounds are empty"

            return nil
        }

        guard markMangoTarget(in: real) else {
            loadError =
                "Mango entity not found in scene"

            return nil
        }

        disableGroundShadow(on: real)

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

        setMangoEchoMat(
            on: pulse,
            alpha: 1.0
        )

        setMangoEchoMat(
            on: trace,
            alpha: 0.25
        )

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

    /// Finds the mango node authored in the composed scene and
    /// renames it to "MangoTarget", the marker the rest of this
    /// service (isInsideMango / setMangoEchoMat) already looks for.
    private func markMangoTarget(
        in root: Entity
    ) -> Bool {
        for child in root.children {
            if child.name == "MangoItem" {
                child.name = "MangoTarget"
                return true
            }

            if markMangoTarget(in: child) {
                return true
            }
        }

        return false
    }

    private func setMangoEchoMat(
        on entity: Entity,
        alpha: Float
    ) {
        if entity.name == "MangoTarget" {
            setYellowEchoMat(
                on: entity,
                alpha: alpha
            )
            return
        }

        for child in entity.children {
            setMangoEchoMat(
                on: child,
                alpha: alpha
            )
        }
    }
    
    private func setYellowEchoMat(
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
                yellowEchoMat(
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
            setYellowEchoMat(
                on: child,
                alpha: alpha
            )
        }
    }
    
    private func yellowEchoMat(
        alpha: Float
    ) -> UnlitMaterial {
        var mat = UnlitMaterial(
            color: UIColor(
                red: 1.0,
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
            
            let isMango =
                isInsideMango(p)

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
                    radius: radius,
                    isMango: isMango
                )
            )
        }

        return parts
    }

    private func isInsideMango(
        _ entity: Entity
    ) -> Bool {
        var current: Entity? = entity

        while let node = current {
            if node.name == "MangoTarget" {
                return true
            }

            current = node.parent
        }

        return false
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

    /// Scales and grounds the whole composed scene (tree + mango,
    /// with their relative placement already authored in RCP) so
    /// its overall height matches treeH.
    private func placeScene(
        _ scene: Entity
    ) -> SIMD3<Float>? {
        let bounds =
            scene.visualBounds(
                recursive: true,
                relativeTo: scene,
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

        scene.scale =
            SIMD3<Float>(
                repeating: scale
            )

        scene.position = SIMD3<Float>(
            -center.x,
            (size.y * 0.5) - center.y,
            -center.z
        )

        return size
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
            Task<Entity, Error>
    ) async -> Bool {
        do {
            let scene =
                try await task.value

            sceneTpl = scene

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
