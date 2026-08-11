//
//  ECSWorld+Wave.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import ARKit
import Foundation
import RealityKit
import simd

extension ECSWorld {
    func sendWave() {
        guard model.lidarOK,
              let scene = anchor.scene,
              let frame = sess.session.currentFrame
        else {
            return
        }

        clearActiveWave()
        trimTraces(max: 3)

        let start = camStart(from: frame.camera.transform)
        let data = waveSim.run(in: scene, from: start)

        model.waveSeq += 1

        showFP(data)
        scanTarget(with: data, in: scene)
    }

    func camStart(
        from matrix: simd_float4x4
    ) -> WaveStart {
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
            pos: matrix.pos3 + (forward * 0.18) - (up * 0.04),
            forward: forward,
            right: right,
            up: up
        )
    }

    func showFP(_ data: WaveData) {
        let root = Entity()
        root.name = "fpReveal"
        root.components[RevealComp.self] = RevealComp(data: data)
        anchor.addChild(root)
    }

    func trimTraces(max: Int) {
        let traces = anchor.children
            .filter {
                $0.components.has(TraceComp.self)
            }
            .sorted {
                let a = $0.components[TraceComp.self]?.createdAt ?? 0
                let b = $1.components[TraceComp.self]?.createdAt ?? 0
                return a < b
            }

        guard traces.count > max else {
            return
        }

        for trace in traces.prefix(traces.count - max) {
            trace.removeFromParent()
        }
    }
}
