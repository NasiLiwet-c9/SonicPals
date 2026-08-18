//
//  TargetAssetSvc.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import Foundation
import RealityKit
import RealityKitContent

@MainActor
final class TargetAssetSvc: TargetMaking {
    private let sceneName: String
    private let sceneSvc: TargetSceneSvc
    private let mangoSvc = TargetMangoSvc()
    private let echoSvc = TargetEchoSvc()
    private let partSvc = TargetPartSvc()

    private var sceneTpl: Entity?
    private var task: Task<Entity, Error>?

    private(set) var loadError: String?

    init(
        sceneName: String = "Mango+Tree",
        treeH: Float = TargetCfg.Tree.height
    ) {
        self.sceneName = sceneName
        sceneSvc = TargetSceneSvc(
            treeH: treeH
        )
    }

    func prepare() async -> Bool {
        if sceneTpl != nil {
            return true
        }

        if let task {
            return await finish(task)
        }

        let name = sceneName

        let newTask = Task {
            @MainActor in

            try await Entity(
                named: name,
                in: realityKitContentBundle
            )
        }

        task = newTask

        return await finish(newTask)
    }

    func make() -> TargetPart? {
        guard let sceneTpl else {
            return fail(
                "Target assets are not ready"
            )
        }

        let real = sceneTpl.clone(
            recursive: true
        )

        real.name = "targetReal"

        sceneSvc.freeze(real)

        guard let size = sceneSvc.place(
            real
        ) else {
            return fail(
                "Scene bounds are empty"
            )
        }

        guard mangoSvc.place(
            in: real
        ) else {
            return fail(
                "Could not place mango at a spawn point"
            )
        }

        guard mangoSvc.mark(
            in: real
        ) else {
            return fail(
                "Mango entity not found in scene"
            )
        }

        sceneSvc.noShadow(real)

        let pulse = real.clone(
            recursive: true
        )

        let trace = real.clone(
            recursive: true
        )

        sceneSvc.freeze(pulse)
        sceneSvc.freeze(trace)

        echoSvc.style(
            pulse: pulse,
            trace: trace
        )

        sceneSvc.noShadow(pulse)
        sceneSvc.noShadow(trace)

        let root = Entity()

        root.name = "target"

        root.addChild(real)
        root.addChild(pulse)
        root.addChild(trace)

        guard let parts = partSvc.make(
            pulse: pulse,
            trace: trace
        ),
        !parts.isEmpty else {
            return fail(
                "Target has no renderable parts"
            )
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
            sceneTpl =
                try await task.value

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

    private func fail(
        _ text: String
    ) -> TargetPart? {
        loadError = text
        return nil
    }
}
