import Combine
import RealityKit

@MainActor
final class ARVM: ObservableObject {
    @Published private(set) var state =
        ARState()

    private let ctrl:
        any SceneControlling

    init() {
        let ctrl = SceneCtrl(
            sess: ARSessSvc(),
            place: PlaceSvc(),
            botMaker: BotMaker(),
            waveSim: WaveSim(),
            waveDraw: WaveDraw()
        )

        self.ctrl = ctrl

        ctrl.onState = {
            [weak self] newState in

            self?.state = newState
        }
    }

    func setup(
        _ view: ARView
    ) {
        ctrl.setup(view)
    }

    func spawn() {
        ctrl.spawn()
    }

    func pulse() {
        ctrl.pulse()
    }

    func turn(
        _ deg: Float
    ) {
        ctrl.turn(deg)
    }

    func toggleMesh() {
        ctrl.toggleMesh()
    }

    func clear() {
        ctrl.clear()
    }
}
