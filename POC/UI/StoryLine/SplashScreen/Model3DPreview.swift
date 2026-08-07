//
//  Model3DPreview.swift
//  POC

//  Created by Asaryun on 07/08/26.

//  Lightweight SceneKit preview for a bundled .usdz — used inside the
//  onboarding cards. Auto-frames the model (computes its bounding box
//  and places a camera to fit it) and gives it a slow idle spin so the
//  card doesn't feel static. No ARKit session involved — this is just
//  a turntable render, not AR.
//

import SwiftUI
import SceneKit

struct Model3DPreview: UIViewRepresentable {
    let resourceName: String

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = .multisampling4X
        view.scene = makeScene()
        view.pointOfView = view.scene?.rootNode.childNode(
            withName: "previewCamera",
            recursively: true
        )

        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
    }

    private func makeScene() -> SCNScene {
        let scene = SCNScene()

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "usdz"),
              let loaded = try? SCNScene(url: url, options: nil) else {
            return scene
        }

        let model = SCNNode()

        for child in loaded.rootNode.childNodes {
            model.addChildNode(child)
        }

        // Center the model on its own bounding box so it rotates in place.
        let (minBox, maxBox) = model.boundingBox

        let center = SCNVector3(
            (minBox.x + maxBox.x) / 2,
            (minBox.y + maxBox.y) / 2,
            (minBox.z + maxBox.z) / 2
        )

        model.position = SCNVector3(-center.x, -center.y, -center.z)
        model.name = "model"

        let extent = SCNVector3(
            maxBox.x - minBox.x,
            maxBox.y - minBox.y,
            maxBox.z - minBox.z
        )

        // Guard against a degenerate/zero-size bounding box (e.g. a
        // model whose geometry didn't parent the way we expected).
        let radius = max(extent.x, max(extent.y, extent.z), 0.05)

        let spin = CABasicAnimation(keyPath: "rotation")
        spin.fromValue = SCNVector4(0, 1, 0, 0)
        spin.toValue = SCNVector4(0, 1, 0, Float.pi * 2)
        spin.duration = 10
        spin.repeatCount = .infinity
        model.addAnimation(spin, forKey: "idleSpin")

        scene.rootNode.addChildNode(model)

        let camera = SCNNode()
        camera.name = "previewCamera"
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = false

        // Scale the clip planes to the model instead of leaving
        // SceneKit's defaults (zNear 1 / zFar 100) — those defaults
        // assume real-world-meter-scale content. Any model smaller
        // than ~0.4m (most of these AR-scale assets) ends up closer
        // to the camera than zNear and gets fully clipped, i.e.
        // renders as nothing even though loading succeeded.
        let distance = Double(radius) * 2.4 + 0.1
        camera.camera?.zNear = Double(radius) * 0.01
        camera.camera?.zFar = distance * 10
        camera.position = SCNVector3(0, 0, Float(distance))
        scene.rootNode.addChildNode(camera)

        return scene
    }
}
