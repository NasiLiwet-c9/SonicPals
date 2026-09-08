//
//  FPScanRead.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import ARKit
import SonarCore
import simd

@MainActor
final class FPScanRead {
    private let hDeg: Float = 38
    private let vDeg: Float = 30
    private let minM: Float = 0.25
    private let maxM: Float = 3.5
    private let maxLimit = 180

    func read(
        session: ARSession,
        camera: simd_float4x4,
        limit: Int = 180
    ) -> [FPTri] {
        guard let frame = session.currentFrame else { return [] }

        let limit = min(max(limit, 24), maxLimit)

        let anchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }

        guard !anchors.isEmpty else { return [] }

        let cone = Cone(camera: camera, hDeg: hDeg, vDeg: vDeg)
        let perAnchor = max(limit / anchors.count, 12)

        var tris: [FPTri] = []
        tris.reserveCapacity(limit)

        for anchor in anchors {
            harvest(
                anchor,
                cone: cone,
                perAnchor: perAnchor,
                limit: limit,
                into: &tris
            )

            if tris.count >= limit { break }
        }

        return tris
    }

    /// The camera's view cone for one frame, so the reach test is not
    /// handed seven loose numbers
    private struct Cone {
        let pos: SIMD3<Float>
        let right: SIMD3<Float>
        let up: SIMD3<Float>
        let forward: SIMD3<Float>
        let hTan: Float
        let vTan: Float

        init(camera: simd_float4x4, hDeg: Float, vDeg: Float) {
            pos = camera.pos3
            right = Cone.axis(camera.columns.0)
            up = Cone.axis(camera.columns.1)

            forward = simd_normalize(
                SIMD3<Float>(
                    -camera.columns.2.x,
                    -camera.columns.2.y,
                    -camera.columns.2.z
                )
            )

            hTan = tan(hDeg * Float.pi / 180)
            vTan = tan(vDeg * Float.pi / 180)
        }

        private static func axis(_ value: SIMD4<Float>) -> SIMD3<Float> {
            simd_normalize(SIMD3<Float>(value.x, value.y, value.z))
        }
    }

    /// Walks one anchor's faces on a stride, keeping the ones in reach
    private func harvest(
        _ anchor: ARMeshAnchor,
        cone: Cone,
        perAnchor: Int,
        limit: Int,
        into tris: inout [FPTri]
    ) {
        let geo = anchor.geometry
        let count = geo.faces.count

        guard count > 0 else { return }

        let step = max(count / perAnchor, 1)
        var index = 0

        while index < count, tris.count < limit {
            let face = geo.face(at: index)

            if face.count == 3 {
                let tri = FPTri(
                    a: worldPos(geo.vertex(at: face[0]), transform: anchor.transform),
                    b: worldPos(geo.vertex(at: face[1]), transform: anchor.transform),
                    c: worldPos(geo.vertex(at: face[2]), transform: anchor.transform)
                )

                if contains(tri.center, in: cone) {
                    tris.append(tri)
                }
            }

            index += step
        }
    }

    private func contains(_ p: SIMD3<Float>, in cone: Cone) -> Bool {
        let delta = p - cone.pos
        let distance = simd_length(delta)

        guard distance >= minM, distance <= maxM else { return false }

        let z = simd_dot(delta, cone.forward)

        guard z > 0.05 else { return false }

        let x = abs(simd_dot(delta, cone.right))
        let y = abs(simd_dot(delta, cone.up))

        return x <= z * cone.hTan && y <= z * cone.vTan
    }

    private func worldPos(
        _ local: SIMD3<Float>,
        transform: simd_float4x4
    ) -> SIMD3<Float> {
        let world = transform * SIMD4<Float>(local.x, local.y, local.z, 1)

        return SIMD3<Float>(world.x, world.y, world.z)
    }
}
