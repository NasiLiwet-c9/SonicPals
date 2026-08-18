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

    var body: some View {
        RealityView { content in
            content.add(world.anchor)
            content.camera = .spatialTracking
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
