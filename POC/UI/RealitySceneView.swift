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

            await world.start()

            guard world.model.lidarOK else {
                return
            }

            content.camera = .spatialTracking
        }
        .onDisappear {
            Task { @MainActor in
                await world.stop()
            }
        }
    }
}
