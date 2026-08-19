//
//  FPScanRead.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import ARKit
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
        guard let frame =
            session.currentFrame else {
            return []
        }

        let limit = min(
            max(
                limit,
                24
            ),
            maxLimit
        )

        let anchors =
            frame.anchors.compactMap {
                $0 as? ARMeshAnchor
            }

        guard !anchors.isEmpty else {
            return []
        }

        let cam =
            camera.pos3

        let right =
            axis(
                camera.columns.0
            )

        let up =
            axis(
                camera.columns.1
            )

        let forward =
            simd_normalize(
                SIMD3<Float>(
                    -camera.columns.2.x,
                    -camera.columns.2.y,
                    -camera.columns.2.z
                )
            )

        let hTan =
            tan(
                hDeg
                * Float.pi
                / 180
            )

        let vTan =
            tan(
                vDeg
                * Float.pi
                / 180
            )

        let perAnchor = max(
            limit
                / anchors.count,
            12
        )

        var tris: [FPTri] = []

        tris.reserveCapacity(
            limit
        )

        for anchor in anchors {
            let geo =
                anchor.geometry

            let count =
                geo.faces.count

            guard count > 0 else {
                continue
            }

            let step = max(
                count
                    / perAnchor,
                1
            )

            var index = 0

            while index < count,
                  tris.count < limit {
                let face =
                    geo.face(
                        at: index
                    )

                if face.count == 3 {
                    let tri =
                        FPTri(
                            a:
                                worldPos(
                                    geo.vertex(
                                        at:
                                            face[0]
                                    ),
                                    transform:
                                        anchor
                                        .transform
                                ),

                            b:
                                worldPos(
                                    geo.vertex(
                                        at:
                                            face[1]
                                    ),
                                    transform:
                                        anchor
                                        .transform
                                ),

                            c:
                                worldPos(
                                    geo.vertex(
                                        at:
                                            face[2]
                                    ),
                                    transform:
                                        anchor
                                        .transform
                                )
                        )

                    if contains(
                        tri.center,
                        camera: cam,
                        right: right,
                        up: up,
                        forward:
                            forward,
                        hTan: hTan,
                        vTan: vTan
                    ) {
                        tris.append(
                            tri
                        )
                    }
                }

                index += step
            }

            if tris.count
                >= limit {
                break
            }
        }

        return tris
    }

    private func contains(
        _ p: SIMD3<Float>,
        camera: SIMD3<Float>,
        right: SIMD3<Float>,
        up: SIMD3<Float>,
        forward: SIMD3<Float>,
        hTan: Float,
        vTan: Float
    ) -> Bool {
        let delta =
            p - camera

        let distance =
            simd_length(
                delta
            )

        guard distance >= minM,
              distance <= maxM else {
            return false
        }

        let z =
            simd_dot(
                delta,
                forward
            )

        guard z > 0.05 else {
            return false
        }

        let x = abs(
            simd_dot(
                delta,
                right
            )
        )

        let y = abs(
            simd_dot(
                delta,
                up
            )
        )

        return x <= z * hTan
            && y <= z * vTan
    }

    private func axis(
        _ value: SIMD4<Float>
    ) -> SIMD3<Float> {
        simd_normalize(
            SIMD3<Float>(
                value.x,
                value.y,
                value.z
            )
        )
    }

    private func worldPos(
        _ local: SIMD3<Float>,
        transform:
            simd_float4x4
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
