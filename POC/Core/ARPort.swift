import ARKit
import RealityKit
import UIKit

@MainActor
protocol SceneControlling: AnyObject {
    var onState: ((ARState) -> Void)? {
        get set
    }

    func setup(
        _ view: ARView
    )

    func spawn()

    func pulse()

    func turn(
        _ deg: Float
    )

    func toggleMesh()

    func clear()
}

@MainActor
protocol ARSessionServing {
    func start(
        _ view: ARView
    ) -> Bool

    func showMesh(
        _ show: Bool,
        in view: ARView
    )

    func addCoach(
        to view: ARView
    )
}

@MainActor
protocol PlaceServing {
    func hit(
        in view: ARView,
        at point: CGPoint
    ) -> ARRaycastResult?
}

@MainActor
protocol BotMaking {
    func make() -> BotPart
}

@MainActor
protocol WaveSimulating {
    func run(
        in view: ARView,
        from sensor: Entity
    ) -> WaveData
}

@MainActor
protocol WaveDrawing {
    func make(
        from data: WaveData
    ) -> Entity
}
