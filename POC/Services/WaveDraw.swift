import RealityKit
import UIKit
import simd

@MainActor
final class WaveDraw:
    WaveDrawing {

    func make(
        from data: WaveData
    ) -> Entity {
        let root = Entity()
        root.name = "wave"

        for seg in data.segs {
            root.addChild(
                makeLine(seg)
            )
        }

        for point in data.hits {
            root.addChild(
                makeDot(at: point)
            )
        }

        return root
    }

    private func makeLine(
        _ seg: WaveSeg
    ) -> ModelEntity {
        let vector =
            seg.end - seg.start

        let rawLength =
            simd_length(vector)

        let length = max(
            rawLength,
            0.001
        )

        let direction =
            rawLength > 0.0001
            ? vector / rawLength
            : SIMD3<Float>(0, 1, 0)

        let line = ModelEntity(
            mesh: .generateCylinder(
                height: length,
                radius: 0.004
            ),
            materials: [
                material(for: seg.type)
            ]
        )

        line.position =
            (seg.start + seg.end) / 2

        line.orientation = simd_quatf(
            from: SIMD3<Float>(
                0,
                1,
                0
            ),
            to: direction
        )

        return line
    }

    private func makeDot(
        at point: SIMD3<Float>
    ) -> ModelEntity {
        let mat = SimpleMaterial(
            color: .white,
            isMetallic: false
        )

        let dot = ModelEntity(
            mesh: .generateSphere(
                radius: 0.012
            ),
            materials: [mat]
        )

        dot.position = point

        return dot
    }

    private func material(
        for type: WaveType
    ) -> SimpleMaterial {
        let color: UIColor

        switch type {
        case .outgoing:
            color = .systemCyan

        case .reflected:
            color = .systemYellow

        case .echo:
            color = .systemGreen
        }

        return SimpleMaterial(
            color: color.withAlphaComponent(
                0.9
            ),
            isMetallic: false
        )
    }
}
