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

    // MARK: - Loading

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

    // MARK: - Make Target

    func make() -> TargetPart? {
        guard let sceneTpl else {
            loadError =
                "Target assets are not ready"

            return nil
        }

        // Create the actual target instance.
        let real =
            sceneTpl.clone(
                recursive: true
            )

        real.name = "targetReal"

        // First scale and ground the entire scene.
        guard let treeSize =
            placeScene(real)
        else {
            loadError =
                "Scene bounds are empty"

            return nil
        }

        // Randomly place the single MangoItem
        // at one of the five authored spawn points.
        guard randomizeMangoPosition(
            in: real
        ) else {
            loadError =
                "Could not place mango at a spawn point"

            return nil
        }

        // Rename MangoItem to MangoTarget because
        // the rest of the target system uses this name.
        guard markMangoTarget(
            in: real
        ) else {
            loadError =
                "Mango entity not found in scene"

            return nil
        }

        disableGroundShadow(
            on: real
        )

        // Clone AFTER randomizing the mango position.
        // This guarantees pulse and trace have the
        // same mango position as the real target.
        let pulse =
            real.clone(
                recursive: true
            )

        let trace =
            real.clone(
                recursive: true
            )

        // MARK: Echo Materials

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

        disableGroundShadow(
            on: pulse
        )

        disableGroundShadow(
            on: trace
        )

        // MARK: Create Parts

        guard let parts =
            makeParts(
                pulse: pulse,
                trace: trace
            ),
            !parts.isEmpty
        else {
            loadError =
                "Target has no renderable parts"

            return nil
        }

        // Real target is initially hidden.
        real.isEnabled = false

        // Echo targets are also initially hidden.
        for part in parts {
            part.pulse.isEnabled = false
            part.trace.isEnabled = false
        }

        // MARK: Root

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

    // MARK: - Mango Spawn

    /// Randomly moves the single MangoItem to one of
    /// the five Transform entities created in
    /// Reality Composer Pro.
    ///
    /// Expected RCP hierarchy:
    ///
    /// Root
    /// ├── MangoItem
    /// ├── TreeItem
    /// ├── MangoSpawnPoint1
    /// ├── MangoSpawnPoint2
    /// ├── MangoSpawnPoint3
    /// ├── MangoSpawnPoint4
    /// └── MangoSpawnPoint5
    ///
    private func randomizeMangoPosition(
        in root: Entity
    ) -> Bool {

        print("")
        print("========================================")
        print("🥭 RANDOMIZING MANGO")
        print("========================================")

        guard let mango =
            findEntityRecursively(
                named: "MangoItem",
                in: root
            )
        else {
            print("❌ MangoItem NOT FOUND")
            printEntityHierarchy(root)
            return false
        }

        let spawnPointNames = [
            "MangoSpawnPoint1",
            "MangoSpawnPoint2",
            "MangoSpawnPoint3",
            "MangoSpawnPoint4",
            "MangoSpawnPoint5"
        ]

        let spawnPoints =
            spawnPointNames.compactMap { name in
                findEntityRecursively(
                    named: name,
                    in: root
                )
            }

        print("📍 Found \(spawnPoints.count)/5 spawn points")

        guard let spawnPoint =
            spawnPoints.randomElement()
        else {
            print("❌ NO SPAWN POINTS FOUND")
            printEntityHierarchy(root)
            return false
        }

        print("🎯 Selected: \(spawnPoint.name)")

        guard let mangoParent = mango.parent else {
            print("❌ MangoItem has no parent")
            return false
        }

        // Convert the spawn point's position into
        // the mango parent's coordinate space.
        let spawnPosition =
            spawnPoint.position(
                relativeTo: mangoParent
            )

        // IMPORTANT:
        // Only change the mango's POSITION.
        // Its original RCP rotation and scale remain untouched.
        mango.position = spawnPosition

        print("✅ Mango moved to \(spawnPoint.name)")
        print("   Position: \(spawnPosition)")
        print("   Scale preserved: \(mango.scale)")

        print("========================================")
        print("")

        return true
    }

    // MARK: - Recursive Entity Search

    /// Recursively searches an Entity and all descendants
    /// for an entity with the specified name.
    private func findEntityRecursively(
        named name: String,
        in entity: Entity
    ) -> Entity? {

        if entity.name == name {
            return entity
        }

        for child in entity.children {
            if let result =
                findEntityRecursively(
                    named: name,
                    in: child
                )
            {
                return result
            }
        }

        return nil
    }

    // MARK: - Entity Debugging

    /// Prints the entire loaded RealityKit entity hierarchy
    /// to the Xcode console.
    private func printEntityHierarchy(
        _ entity: Entity,
        indent: String = ""
    ) {
        let modelMarker =
            entity.components.has(
                ModelComponent.self
            )
            ? " [MODEL]"
            : ""

        print(
            "\(indent)• \(entity.name)\(modelMarker)"
        )

        for child in entity.children {
            printEntityHierarchy(
                child,
                indent: indent + "  "
            )
        }
    }

    // MARK: - Mango Target

    /// Finds the mango node authored in the composed scene
    /// and renames it to "MangoTarget".
    private func markMangoTarget(
        in root: Entity
    ) -> Bool {

        if root.name == "MangoItem" {
            root.name = "MangoTarget"
            return true
        }

        for child in root.children {
            if markMangoTarget(
                in: child
            ) {
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

        mat.blending =
            .transparent(
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

    // MARK: - Parts

    private func makeParts(
        pulse: Entity,
        trace: Entity
    ) -> [TargetEchoPart]? {

        let pulseModels =
            modelEntities(
                in: pulse
            )

        let traceModels =
            modelEntities(
                in: trace
            )

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

            let p =
                pulseModels[index]

            let t =
                traceModels[index]

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
                    ) * 0.5,
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

        var current:
            Entity? = entity

        while let node = current {

            if node.name == "MangoTarget" {
                return true
            }

            current =
                node.parent
        }

        return false
    }

    private func modelEntities(
        in root: Entity
    ) -> [Entity] {

        var result:
            [Entity] = []

        func walk(
            _ entity: Entity
        ) {
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

    // MARK: - Scene Placement

    /// Scales and grounds the whole composed scene
    /// so its overall height matches treeH.
    private func placeScene(
        _ scene: Entity
    ) -> SIMD3<Float>? {

        let bounds =
            scene.visualBounds(
                recursive: true,
                relativeTo: scene,
                excludeInactive: false
            )

        guard bounds.extents.y > 0.001
        else {
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

        scene.position =
            SIMD3<Float>(
                -center.x,
                (size.y * 0.5) - center.y,
                -center.z
            )

        return size
    }

    // MARK: - Echo Materials

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
            color: .white
        )

        mat.triangleFillMode = .fill
        mat.faceCulling = .none
        mat.readsDepth = true
        mat.writesDepth = false

        mat.blending =
            .transparent(
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

    // MARK: - Loading Completion

    private func finish(
        _ task:
            Task<Entity, Error>
    ) async -> Bool {

        do {
            let scene =
                try await task.value

            sceneTpl =
                scene

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
