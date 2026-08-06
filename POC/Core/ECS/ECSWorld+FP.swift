//
//  ECSWorld+FP.swift
//  POC
//
//  Replaces FP/Scene/SceneCtrl+FP.swift. The old
//  FP/Scene/SceneCtrl+FPAnim.swift (loadFPMesh/revealFP/hideFP/finishFP)
//  is gone entirely — that job now belongs to FPRevealSystem, a real
//  per-frame RealityKit System. This file's only job is to build the
//  visual root, attach the FPRevealComponent describing what it should
//  do, and hand it off.
//

import Foundation
import RealityKit
import simd

extension ECSWorld {
    func camStart(in view: ARView) -> WaveStart {
        let matrix = view.cameraTransform.matrix

        let forward = simd_normalize(
            SIMD3<Float>(
                -matrix.columns.2.x,
                 -matrix.columns.2.y,
                 -matrix.columns.2.z
            )
        )

        let right = simd_normalize(
            SIMD3<Float>(
                matrix.columns.0.x,
                matrix.columns.0.y,
                matrix.columns.0.z
            )
        )

        let up = simd_normalize(
            SIMD3<Float>(
                matrix.columns.1.x,
                matrix.columns.1.y,
                matrix.columns.1.z
            )
        )

        let camPos = SIMD3<Float>(
            matrix.columns.3.x,
            matrix.columns.3.y,
            matrix.columns.3.z
        )

        return WaveStart(
            pos: camPos + (forward * 0.18) - (up * 0.04),
            forward: forward,
            right: right,
            up: up
        )
    }

    func showFP(_ data: WaveData, in view: ARView) {
        let root = Entity()
        root.name = "fpVision"

        root.addChild(fpCone.make(from: data))

        root.components[WaveVisualComponent.self] = WaveVisualComponent(kind: .fp)

        root.components[FPRevealComponent.self] = FPRevealComponent(
            data: data,
            fpMesh: fpMesh,
            view: view,
            root: root,
            onFinished: { [weak self] in
                self?.finishFP(root)
            }
        )

        anchor.addChild(root)

        visualEntity = root
        model.hasWave = true

        showFPMsg(data)
    }

    private func finishFP(_ root: Entity) {
        guard visualEntity === root else {
            return
        }

        visualEntity = nil
        model.hasWave = false
    }

    private func showFPMsg(_ data: WaveData) {
        guard let hit = data.nearestHit else {
            setMsg("BAT VISION • no surface inside the scan area")
            return
        }

        let distance = String(format: "%.2f m", Double(hit.distanceM))

        setMsg("BAT VISION • \(data.setting.mode.title) • mesh at \(distance)")
    }
}
