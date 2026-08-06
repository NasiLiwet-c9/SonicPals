//
//  ECSWorld.swift
//  POC
//
//  Replaces both ARVM (the MVVM view model) and SceneCtrl (the god
//  object it wrapped). ECSWorld is deliberately thin:
//
//   - it owns the ARView / world anchor and the *stateless* algorithm
//     services (wave sim, mesh builders, etc.) — unchanged from before
//   - domain state lives on Components attached to entities, not on
//     this class (see Components.swift)
//   - `perform(_:)` is the single entry point SwiftUI/gestures call;
//     each command is handled by mutating components, in
//     ECSWorld+Placement / +Wave / +FP / +TP
//   - `AppModel` is refreshed from component state after every command
//     so SwiftUI has something simple to bind to
//   - the one genuinely time-based behaviour (the BAT VISION mesh
//     reveal/hide sequence) is NOT handled here — it's delegated to
//     FPRevealSystem, a real per-frame RealityKit System
//

import RealityKit
import ARKit
import UIKit
import simd

@MainActor
@Observable
final class ECSWorld: NSObject, UIGestureRecognizerDelegate {
    private(set) var model = AppModel()

    weak var ar: ARView?
    let anchor = AnchorEntity(world: .zero)

    // Entities that domain Components attach to.
    let sessionEntity = Entity()
    var objectEntity: Entity?
    var waveStartEntity: Entity?
    var visualEntity: Entity?

    var lastData: WaveData?

    // Stateless services / algorithms — same composition as before,
    // just no longer owned by a god object.
    let sess: any ARSessionServing
    let objectMaker: any ObjectMaking
    let tpSpawn: any TPSpawning
    let waveSim: any WaveSimulating
    let fpCone: any FPConeDrawing
    let fpMesh: any FPMeshBuilding
    let waveDraw: any WaveDrawing

    override init() {
        let waveShape = WaveShape()
        let coneShape = FPConeShape()
        let meshRead = FPMeshRead()
        let meshPack = FPMeshPack(liftM: 0.018)
        let meshFact = FPMeshFact()

        let meshBuild = FPMeshBuild(
            read: meshRead,
            pack: meshPack,
            fact: meshFact
        )

        let objectMaker = ObjectMaker(
            asset: TPAssetSvc(
                name: "Bat3",
                targetSpanM: 0.34
            )
        )

        self.sess = ARSessSvc()
        self.objectMaker = objectMaker
        self.tpSpawn = TPSpawn(frontM: 0.85, downM: 0.18)
        self.waveSim = WaveSim()
        self.fpCone = FPConeDraw(shape: coneShape)
        self.fpMesh = meshBuild
        self.waveDraw = WaveDraw(shape: waveShape)

        super.init()

        FPRevealSystem.registerSystem()
        sessionEntity.components.set(SessionComponent())
    }

    func setup(_ view: ARView) {
        guard ar == nil else {
            return
        }

        ar = view

        let supported = sess.start(view)

        view.scene.addAnchor(anchor)
        anchor.addChild(sessionEntity)

        var session = sessionEntity.components[SessionComponent.self]
            ?? SessionComponent()

        session.lidarOK = supported
        session.meshOn = false
        sessionEntity.components[SessionComponent.self] = session

        model.lidarOK = supported
        model.meshOn = false

        model.msg = supported
            ? "BAT VISION ready, move phone to aim"
            : "LiDAR scene reconstruction unavailable"

        sess.showMesh(false, in: view)
        sess.addCoach(to: view)
        addPan(to: view)

        // Preload Bat3 before the user presses Place.
        Task { [weak self] in
            guard let self else {
                return
            }

            _ = await self.objectMaker.prepare()
        }
    }

    func perform(_ command: ECSCommand) {
        switch command {
        case .place:
            place()
        case .sendWave:
            sendWave()
        case let .turn(deg):
            turn(deg)
        case .toggleMesh:
            toggleMesh()
        case .togglePoints:
            togglePoints()
        case .toggleView:
            toggleView()
        case .clear:
            clear()
        case .memoryWarning:
            handleMemoryWarning()
        case .dragBegan:
            dragBegan()
        case let .dragChanged(translation):
            dragChanged(translation)
        case .dragEnded:
            dragEnded()
        case .dragCancelled:
            dragCancelled()
        }
    }

    func toggleMesh() {
        guard model.viewMode == .third else {
            setMsg("The full mesh stays hidden in BAT VISION")
            return
        }

        guard let ar else {
            return
        }

        var session = sessionEntity.components[SessionComponent.self]
            ?? SessionComponent()

        guard session.lidarOK else {
            return
        }

        session.meshOn.toggle()
        sessionEntity.components[SessionComponent.self] = session

        sess.showMesh(session.meshOn, in: ar)
        model.meshOn = session.meshOn

        setMsg(session.meshOn ? "Mesh visible" : "Mesh hidden")
    }

    func handleMemoryWarning() {
        clearWave()

        if let ar {
            sess.showMesh(false, in: ar)
        }

        var session = sessionEntity.components[SessionComponent.self]
            ?? SessionComponent()

        session.meshOn = false
        sessionEntity.components[SessionComponent.self] = session

        model.meshOn = false
        model.pointsOn = false

        setMsg("Temporary wave graphics cleared")
    }

    func clearWave() {
        visualEntity?.components[FPRevealComponent.self] = nil
        visualEntity?.removeFromParent()
        visualEntity = nil
        lastData = nil

        model.hasWave = false
    }

    func setMsg(_ text: String) {
        model.msg = text
    }

    private func addPan(to view: ARView) {
        let pan = UIPanGestureRecognizer(
            target: self,
            action: #selector(drag(_:))
        )

        pan.cancelsTouchesInView = false
        pan.maximumNumberOfTouches = 1
        pan.delegate = self

        view.addGestureRecognizer(pan)
    }

    @objc private func drag(_ pan: UIPanGestureRecognizer) {
        guard let ar else {
            return
        }

        switch pan.state {
        case .began:
            perform(.dragBegan)
            pan.setTranslation(.zero, in: ar)

        case .changed:
            perform(.dragChanged(pan.translation(in: ar)))

        case .ended:
            perform(.dragEnded)

        case .cancelled, .failed:
            perform(.dragCancelled)

        default:
            break
        }
    }

    nonisolated func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
