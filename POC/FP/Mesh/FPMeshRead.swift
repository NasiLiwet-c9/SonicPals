//
//  FPMeshRead.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import ARKit
import RealityKit
import simd

@MainActor
final class FPMeshRead: FPMeshReadPort {
    func read(
        in view: ARView,
        cone: FPConeScan,
        limit: Int
    ) -> [FPTri] {
        guard let frame =
            view.session.currentFrame
        else {
            return []
        }

        let anchors =
            frame.anchors.compactMap {
                $0 as? ARMeshAnchor
            }

        var tris: [FPTri] = []

        tris.reserveCapacity(
            min(limit, 12_000)
        )

        for anchor in anchors {
            guard anchorIntersects(
                anchor,
                cone: cone
            ) else {
                continue
            }

            let geo = anchor.geometry

            for faceIndex in 0..<geo.faces.count {
                let face =
                    geo.face(
                        at: faceIndex
                    )

                guard face.count == 3 else {
                    continue
                }

                let tri = FPTri(
                    a: worldPos(
                        geo.vertex(
                            at: face[0]
                        ),
                        transform:
                            anchor.transform
                    ),
                    b: worldPos(
                        geo.vertex(
                            at: face[1]
                        ),
                        transform:
                            anchor.transform
                    ),
                    c: worldPos(
                        geo.vertex(
                            at: face[2]
                        ),
                        transform:
                            anchor.transform
                    )
                )

                guard tri.points.contains(
                    where: {
                        cone.contains(
                            $0,
                            pad: 1.10
                        )
                    }
                ) else {
                    continue
                }

                tris.append(tri)
            }
        }

        return evenlyLimited(
            tris,
            limit: limit
        )
    }

    private func anchorIntersects(
        _ anchor: ARMeshAnchor,
        cone: FPConeScan
    ) -> Bool {
        let geo = anchor.geometry
        let count = geo.vertices.count

        guard count > 0 else {
            return false
        }

        var minP = SIMD3<Float>(
            repeating:
                Float.greatestFiniteMagnitude
        )

        var maxP = SIMD3<Float>(
            repeating:
                -Float.greatestFiniteMagnitude
        )

        for index in 0..<count {
            let p =
                geo.vertex(
                    at: UInt32(index)
                )

            minP = SIMD3<Float>(
                min(minP.x, p.x),
                min(minP.y, p.y),
                min(minP.z, p.z)
            )

            maxP = SIMD3<Float>(
                max(maxP.x, p.x),
                max(maxP.y, p.y),
                max(maxP.z, p.z)
            )
        }

        let center =
            worldPos(
                (minP + maxP) * 0.5,
                transform:
                    anchor.transform
            )

        let radius =
            simd_length(
                maxP - minP
            )
            * 0.5

        return cone.intersectsSphere(
            center: center,
            radius: radius,
            pad: 1.12
        )
    }

    private func evenlyLimited(
        _ tris: [FPTri],
        limit: Int
    ) -> [FPTri] {
        guard limit > 0,
              tris.count > limit else {
            return tris
        }

        let step =
            Double(tris.count)
            / Double(limit)

        return (0..<limit).map { index in
            let source =
                min(
                    Int(
                        (
                            Double(index)
                            * step
                        )
                        .rounded(.down)
                    ),
                    tris.count - 1
                )

            return tris[source]
        }
    }

    private func worldPos(
        _ local: SIMD3<Float>,
        transform: simd_float4x4
    ) -> SIMD3<Float> {
        let world =
            transform
            * SIMD4<Float>(
                local.x,
                local.y,
                local.z,
                1
            )

        return SIMD3<Float>(
            world.x,
            world.y,
            world.z
        )
    }
}
