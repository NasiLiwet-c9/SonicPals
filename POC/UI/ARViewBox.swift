import RealityKit
import SwiftUI

@MainActor
struct ARViewBox: UIViewRepresentable {
    @ObservedObject var vm: ARVM

    func makeUIView(
        context: Context
    ) -> ARView {
        let view = ARView(
            frame: .zero,
            cameraMode: .ar,
            automaticallyConfigureSession: false
        )

        vm.setup(view)

        return view
    }

    func updateUIView(
        _ uiView: ARView,
        context: Context
    ) {
        // SceneCtrl manages the ARView.
    }
}
