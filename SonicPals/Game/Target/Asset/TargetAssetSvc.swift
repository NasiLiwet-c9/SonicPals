//
//  TargetAssetSvc.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import Foundation
import RealityKit
import RealityKitContent
import UIKit

@MainActor
final class TargetAssetSvc: TargetMaking {
    /// Shared, so the loading screen warms the maker `ECSWorld` uses
    static let shared = TargetAssetSvc()

    private let sceneName: String
    private let sceneSvc: TargetSceneSvc
    private let mangoSvc = TargetMangoSvc()
    private let echoSvc = TargetEchoSvc()
    private let partSvc = TargetPartSvc()

    private var sceneTpl: Entity?
    private var task: Task<Entity, Error>?

    /// Built in advance, handed out by `make`
    private var spare: TargetPart?

    private(set) var loadError: String?

    init(
        sceneName: String = "Mango+Tree",
        treeH: Float = TargetCfg.Tree.height
    ) {
        self.sceneName = sceneName
        sceneSvc = TargetSceneSvc(treeH: treeH)
    }

    func prepare() async -> Bool {
        if sceneTpl != nil {
            return true
        }

        if let task {
            return await finish(task)
        }

        let name = sceneName

        let newTask = Task { @MainActor in
            try await Entity(
                named: name,
                in: realityKitContentBundle
            )
        }

        task = newTask

        return await finish(newTask)
    }

    /// ARKit's estimate of an unlit room leaves the tree nearly black,
    /// and the room mesh is occlusion-only, so this lights nothing else
    private func makeLight(height: Float) -> Entity {
        let entity = Entity()

        entity.components.set(
            PointLightComponent(
                color: .white,
                intensity: 2400,
                attenuationRadius: max(height * 2.2, 2.4)
            )
        )

        entity.position = SIMD3<Float>(0, height * 0.75, 0.35)

        return entity
    }

    /// Built during the scan or the lesson, so spawning is a reparent
    func prewarm() async {
        guard spare == nil, sceneTpl != nil else { return }

        // Off this runloop turn, so a mid-frame caller is not stalled
        await Task.yield()

        guard spare == nil else { return }

        spare = build()
    }

    func make() -> TargetPart? {
        if let ready = spare {
            spare = nil

            Task { @MainActor [weak self] in
                await self?.prewarm()
            }

            return ready
        }

        return build()
    }

    private func build() -> TargetPart? {
        guard let sceneTpl else {
            return fail("Target assets are not ready")
        }

        let real = sceneTpl.clone(recursive: true)
        real.name = "targetReal"

        sceneSvc.freeze(real)

        guard let size = sceneSvc.place(real) else {
            return fail("Scene bounds are empty")
        }

        guard mangoSvc.place(in: real) else {
            return fail("Could not place mango at a spawn point")
        }

        guard mangoSvc.mark(in: real) else {
            return fail("Mango entity not found in scene")
        }

        sceneSvc.noShadow(real)
        sceneSvc.muteParticles(real)

        // Clone sonar before changing real model color
        let pulse = real.clone(recursive: true)
        let trace = real.clone(recursive: true)

        // Real target above mission shade
        RealityShade.keepBright(
            real,
            order: 1
        )

        // Darker RGB only. Opacity stays unchanged
        sceneSvc.dim(
            real,
            factor: TargetCfg.Tree.realDim
        )

        sceneSvc.freeze(pulse)
        sceneSvc.freeze(trace)

        sceneSvc.muteParticles(pulse)
        sceneSvc.muteParticles(trace)

        echoSvc.style(
            pulse: pulse,
            trace: trace
        )

        sceneSvc.noShadow(pulse)
        sceneSvc.noShadow(trace)

        let root = Entity()
        root.name = "target"

        real.addChild(makeLight(height: size.y))

        root.addChild(real)
        root.addChild(pulse)
        root.addChild(trace)

        guard let parts = partSvc.make(
            pulse: pulse,
            trace: trace
        ),
        !parts.isEmpty else {
            return fail("Target has no renderable parts")
        }

        real.isEnabled = false

        for part in parts {
            part.pulse.isEnabled = false
            part.trace.isEnabled = false
        }

        loadError = nil

        return TargetPart(
            root: root,
            real: real,
            parts: parts,
            height: size.y
        )
    }

    private func finish(
        _ task: Task<Entity, Error>
    ) async -> Bool {
        do {
            sceneTpl = try await task.value
            self.task = nil
            loadError = nil
            return true
        } catch {
            self.task = nil
            loadError = error.localizedDescription
            return false
        }
    }

    private func fail(_ text: String) -> TargetPart? {
        loadError = text
        return nil
    }
}
