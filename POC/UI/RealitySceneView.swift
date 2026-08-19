//
//  RealitySceneView.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import RealityKit
import SwiftUI

@MainActor
struct RealitySceneView: View {
    let world: ECSWorld
    @State private var shadeAnchor: AnchorEntity

    init(world: ECSWorld) {
        self.world = world
        _shadeAnchor = State(
            initialValue: RealityShade.makeAnchor()
        )
    }

    var body: some View {
        let showShade = world.model.hudStage == .mission
        let dim = world.model.dimOn

        RealityView { content in
            content.add(world.anchor)
            content.add(shadeAnchor)
            content.camera = .spatialTracking

            await RealityShade.prepare(shadeAnchor)

            RealityShade.update(
                shadeAnchor,
                visible: showShade,
                dim: dim
            )
        } update: { _ in
            RealityShade.update(
                shadeAnchor,
                visible: showShade,
                dim: dim
            )
        }
        .task {
            await world.start()
        }
        .onDisappear {
            Task { @MainActor in
                await world.stop()
            }
        }
    }
}
