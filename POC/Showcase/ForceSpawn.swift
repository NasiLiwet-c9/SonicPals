//
//  ForceSpawn.swift
//  POC
//
//  Created by Shan Newcastle on 19/08/26.
//

import ARKit
import RealityKit
import SwiftUI
import UIKit
import simd

@MainActor
final class ForceSpawnRuntime {
    static let shared = ForceSpawnRuntime()

    private weak var owner: ECSWorld?
    private(set) var active = false

    func activate(for world: ECSWorld) {
        owner = world
        active = true
    }

    func isActive(for world: ECSWorld) -> Bool {
        active && owner === world
    }
}

@MainActor
struct ForceSpawnSecret: View {
    let world: ECSWorld

    @State private var showToast = false
    @State private var toastID = 0

    var body: some View {
        ZStack(alignment: .top) {
            ForceSpawnInstaller {
                activate()
            }
            .frame(width: 0, height: 0)

            if showToast {
                Label("Force Spawn Active", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 58)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    private func activate() {
        guard world.activateForceSpawnSecret() else { return }

        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        toastID += 1
        let id = toastID

        withAnimation(.easeOut(duration: 0.2)) {
            showToast = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1600))

            guard id == toastID else { return }

            withAnimation(.easeIn(duration: 0.2)) {
                showToast = false
            }
        }
    }
}

@MainActor
private struct ForceSpawnInstaller: UIViewRepresentable {
    let onTrigger: @MainActor () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTrigger: onTrigger)
    }

    func makeUIView(context: Context) -> InstallerView {
        let view = InstallerView()
        view.isUserInteractionEnabled = false

        view.onWindow = { window in
            context.coordinator.install(on: window)
        }

        return view
    }

    func updateUIView(_ uiView: InstallerView, context: Context) {
        context.coordinator.onTrigger = onTrigger
    }

    static func dismantleUIView(_ uiView: InstallerView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class InstallerView: UIView {
        var onWindow: ((UIWindow?) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            onWindow?(window)
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        weak var host: UIWindow?
        var gesture: UILongPressGestureRecognizer?
        var onTrigger: @MainActor () -> Void

        init(onTrigger: @escaping @MainActor () -> Void) {
            self.onTrigger = onTrigger
        }

        func install(on window: UIWindow?) {
            guard let window, host !== window else { return }

            uninstall()

            let gesture = UILongPressGestureRecognizer(
                target: self,
                action: #selector(trigger(_:))
            )

            gesture.minimumPressDuration = 2.5
            gesture.numberOfTouchesRequired = 4
            gesture.allowableMovement = 18
            gesture.cancelsTouchesInView = false
            gesture.delaysTouchesBegan = false

            window.addGestureRecognizer(gesture)

            host = window
            self.gesture = gesture
        }

        func uninstall() {
            if let gesture {
                host?.removeGestureRecognizer(gesture)
            }

            gesture = nil
            host = nil
        }

        @objc
        private func trigger(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            onTrigger()
        }
    }
}

extension ECSWorld {
    @discardableResult
    func activateForceSpawnSecret() -> Bool {
        guard model.lidarOK else { return false }

        ForceSpawnRuntime.shared.activate(for: self)
        targetReserve.clear()
        model.msg = ""

        if model.hudStage == .scanning {
            missionTask?.cancel()
            missionTask = nil

            endScan()
            model.scanTurn = .none
            model.scanProgress = 1
            model.scanReady = true
        } else if model.hudStage == .mission {
            missionTask?.cancel()
            missionTask = nil

            Task { @MainActor [weak self] in
                guard let self else { return }
                _ = await forceSpawnTargetNow(showError: false)
            }
        }

#if DEBUG
        print("[FORCE SPAWN] ACTIVE")
#endif

        return true
    }

    func forceSpawnTargetNow(showError: Bool) async -> Bool {
        guard model.lidarOK,
              let frame = sess.session.currentFrame,
              var sessComp = sessEntity.components[SessComp.self],
              !sessComp.spawning else {
            return false
        }

        sessComp.spawning = true
        sessEntity.components[SessComp.self] = sessComp

        if showError { setMsg("") }

        defer {
            if var comp = sessEntity.components[SessComp.self] {
                comp.spawning = false
                sessEntity.components[SessComp.self] = comp
            }
        }

        guard await targetMaker.prepare() else {
            if showError {
                setMsg(targetMaker.loadError ?? "Target could not load")
            }
            return false
        }

        guard let part = targetMaker.make() else {
            if showError {
                setMsg(targetMaker.loadError ?? "Target could not load")
            }
            return false
        }

        let pose = forcePose(frame: frame)

        clearActiveWave()
        clearTraces()
        targetReserve.clear()

        targetEntity?.removeFromParent()
        targetEntity = nil
        eatCandidate = nil

        part.root.stopAllAnimations(recursive: true)

        part.root.components[TargetComp.self] = TargetComp(
            real: part.real,
            parts: part.parts,
            lockPos: pose.pos,
            lockYaw: pose.yaw
        )

        anchor.addChild(part.root)
        part.root.setPosition(pose.pos, relativeTo: nil)

        part.root.setOrientation(
            simd_quatf(angle: pose.yaw, axis: SIMD3<Float>(0, 1, 0)),
            relativeTo: nil
        )

        targetEntity = part.root
        lastTargetPos = pose.pos

        model.hasTarget = true
        model.targetFound = false
        model.mangoEatReady = false
        model.msg = ""

#if DEBUG
        print(
            String(
                format: "[FORCE SPAWN] x=%.2f y=%.2f z=%.2f",
                pose.pos.x,
                pose.pos.y,
                pose.pos.z
            )
        )
#endif

        return true
    }

    private func forcePose(frame: ARFrame) -> TargetPose {
        let camera = frame.camera.transform
        let cam = camera.pos3

        var back = SIMD3<Float>(
            camera.columns.2.x,
            0,
            camera.columns.2.z
        )

        if simd_length(back) < 0.001 {
            back = SIMD3<Float>(0, 0, 1)
        } else {
            back = simd_normalize(back)
        }

        var pos = cam + (back * 1.0)
        pos.y = forceFloorY(at: pos, frame: frame)

        let toCamera = SIMD3<Float>(
            cam.x - pos.x,
            0,
            cam.z - pos.z
        )

        let yaw = atan2(toCamera.x, toCamera.z)

        return TargetPose(pos: pos, yaw: yaw)
    }

    private func forceFloorY(at pos: SIMD3<Float>, frame: ARFrame) -> Float {
        let planes = frame.anchors
            .compactMap { $0 as? ARPlaneAnchor }
            .filter { $0.alignment == .horizontal }

        let floors = planes.filter { $0.classification == .floor }

        if let floorY = floors.map({ $0.transform.pos3.y }).min() {
            return floorY
        }

        if let lowY = planes.map({ $0.transform.pos3.y }).min() {
            return lowY
        }

        let query = ARRaycastQuery(
            origin: pos + SIMD3<Float>(0, 1.5, 0),
            direction: SIMD3<Float>(0, -1, 0),
            allowing: .estimatedPlane,
            alignment: .horizontal
        )

        if let hit = sess.session.raycast(query).first {
            return hit.worldTransform.pos3.y
        }

        return frame.camera.transform.pos3.y - 1.25
    }
}
