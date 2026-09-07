//
//  FPMeshFact.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import RealityKit
import SonarCore
import UIKit

@MainActor
final class FPMeshFact: FPMeshMakePort {
    private let waveMs: Float = 850

    func make(
        from data: FPMeshData,
        key: FPKey,
        range: Float
    ) -> FPMeshLayer? {
        guard !data.pos.isEmpty,
              !data.idx.isEmpty,
              let minM = data.minM else {
            return nil
        }

        var desc = MeshDescriptor(
            name: "fp\(key.band.rawValue)\(key.zone.rawValue)"
        )

        desc.positions = .init(data.pos)
        desc.primitives = .triangles(data.idx)

        guard let mesh = try? MeshResource.generate(from: [desc]) else {
            return nil
        }

        let style = key.style

        let root = Entity()
        let pulse = Entity()
        let trace = Entity()

        root.isEnabled = false
        trace.isEnabled = false

        let fill = ModelEntity(
            mesh: mesh,
            materials: [
                makeMat(
                    color: style.color,
                    alpha: style.fillA,
                    lines: false
                )
            ]
        )

        let wire = ModelEntity(
            mesh: mesh,
            materials: [
                makeMat(
                    color: style.color,
                    alpha: style.wireA,
                    lines: true
                )
            ]
        )

        let traceWire = ModelEntity(
            mesh: mesh,
            materials: [
                makeMat(
                    color: style.color,
                    alpha: traceAlpha(style.wireA),
                    lines: true
                )
            ]
        )

        pulse.addChild(fill)
        pulse.addChild(wire)
        trace.addChild(traceWire)

        root.addChild(pulse)
        root.addChild(trace)

        RealityShade.keepBright(root)

        let amount = min(
            max(minM / max(range, 0.1), 0.03),
            1
        )

        let travelMs = Int64(
            (amount * waveMs).rounded()
        )

        return FPMeshLayer(
            root: root,
            pulse: pulse,
            trace: trace,
            delayMs: travelMs + style.delayMs,
            zone: key.zone
        )
    }

    private func traceAlpha(_ source: Float) -> Float {
        min(
            max(source * 0.06, 0.02),
            0.06
        )
    }

    private func makeMat(
        color: UIColor,
        alpha: Float,
        lines: Bool
    ) -> UnlitMaterial {
        var mat = UnlitMaterial(color: color)

        mat.triangleFillMode = lines ? .lines : .fill
        mat.faceCulling = .none

        // Normal sonar respects RealityKit depth + scene occlusion
        mat.readsDepth = true
        mat.writesDepth = false

        mat.blending = .transparent(
            opacity: .init(
                floatLiteral: min(max(alpha, 0), 1)
            )
        )

        return mat
    }
}
