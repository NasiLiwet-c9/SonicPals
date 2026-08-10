//
//  ECSWorld+Wave.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import Foundation
import RealityKit
import simd

extension ECSWorld {
    func sendWave() {
        guard let ar, model.lidarOK else {
            return
        }

        clearActiveWave()
        trimTraces(max: 3)

        let start = camStart(in: ar)
        let data = waveSim.run(in: ar, from: start)

        model.waveSeq += 1

        showFP(data, in: ar)
        scanTarget(with: data, in: ar)
    }

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

        return WaveStart(
            pos: matrix.pos3
                + (forward * 0.18)
                - (up * 0.04),
            forward: forward,
            right: right,
            up: up
        )
    }

    func showFP(
        _ data: WaveData,
        in view: ARView
    ) {
        let root = Entity()

        root.name = "fpReveal"

        root.components[RevealComp.self] = RevealComp(
            data: data,
            view: ARViewRef(view)
        )

        anchor.addChild(root)
    }

    func trimTraces(max: Int) {
        let traces =
            anchor.children
                .filter {
                    $0.components.has(
                        TraceComp.self
                    )
                }
                .sorted {
                    let a =
                        $0.components[TraceComp.self]?.createdAt
                        ?? 0

                    let b =
                        $1.components[TraceComp.self]?.createdAt
                        ?? 0

                    return a < b
                }

        guard traces.count > max else {
            return
        }

        for trace in traces.prefix(
            traces.count - max
        ) {
            trace.removeFromParent()
        }
    }
}
