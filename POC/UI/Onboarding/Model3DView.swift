//
//  Model3DView.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import SceneKit
import SwiftUI

struct Model3DView:
    UIViewRepresentable {

    let name: String

    func makeUIView(
        context: Context
    ) -> SCNView {
        let view = SCNView()

        view.backgroundColor = .clear
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = .multisampling4X
        view.scene = makeScene()

        view.pointOfView =
            view.scene?
                .rootNode
                .childNode(
                    withName:
                        "previewCamera",
                    recursively: true
                )

        return view
    }

    func updateUIView(
        _ uiView: SCNView,
        context: Context
    ) {}

    private func makeScene() -> SCNScene {
        let scene = SCNScene()

        guard let url =
            Bundle.main.url(
                forResource: name,
                withExtension: "usdz"
            ),
            let source =
                try? SCNScene(
                    url: url,
                    options: nil
                )
        else {
            return scene
        }

        let model = SCNNode()

        for child in source.rootNode.childNodes {
            model.addChildNode(child)
        }

        let box = model.boundingBox

        let center = SCNVector3(
            (box.min.x + box.max.x) / 2,
            (box.min.y + box.max.y) / 2,
            (box.min.z + box.max.z) / 2
        )

        let extent = SCNVector3(
            box.max.x - box.min.x,
            box.max.y - box.min.y,
            box.max.z - box.min.z
        )

        let radius =
            max(
                extent.x,
                max(
                    extent.y,
                    extent.z
                ),
                0.05
            )

        model.position = SCNVector3(
            -center.x,
            -center.y,
            -center.z
        )

        let spin =
            CABasicAnimation(
                keyPath: "rotation"
            )

        spin.fromValue =
            SCNVector4(
                0,
                1,
                0,
                0
            )

        spin.toValue =
            SCNVector4(
                0,
                1,
                0,
                Float.pi * 2
            )

        spin.duration = 10
        spin.repeatCount = .infinity

        model.addAnimation(
            spin,
            forKey: "spin"
        )

        scene.rootNode.addChildNode(
            model
        )

        let camera = SCNNode()

        let distance =
            Double(radius)
            * 2.4
            + 0.1

        camera.name =
            "previewCamera"

        camera.camera =
            SCNCamera()

        camera.camera?.zNear =
            max(
                Double(radius)
                * 0.01,
                0.001
            )

        camera.camera?.zFar =
            distance * 10

        camera.position =
            SCNVector3(
                0,
                0,
                Float(distance)
            )

        scene.rootNode.addChildNode(
            camera
        )

        return scene
    }
}
