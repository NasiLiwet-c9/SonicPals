//
//  ARViewBox.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import ARKit
import RealityKit
import SwiftUI

@MainActor
struct ARViewBox: UIViewRepresentable {
    let world: ECSWorld

    func makeUIView(
        context: Context
    ) -> ARView {
        let view = ARView(
            frame: .zero,
            cameraMode: .ar,
            automaticallyConfigureSession: false
        )

        world.setup(view)

        return view
    }

    func updateUIView(
        _ uiView: ARView,
        context: Context
    ) {}

    static func dismantleUIView(
        _ uiView: ARView,
        coordinator: Void
    ) {
        uiView.session.pause()
        uiView.debugOptions = []

        for anchor in Array(
            uiView.scene.anchors
        ) {
            anchor.removeFromParent()
        }
    }
}
