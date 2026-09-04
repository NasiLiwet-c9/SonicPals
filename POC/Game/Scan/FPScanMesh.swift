//
//  FPScanMesh.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import Foundation
import RealityKit
import SonarCore
import UIKit
import simd

@MainActor
final class FPScanMesh {
    private let maxTris = 1_200
    private let liftM: Float = 0.007

    private let minAddS:
        TimeInterval = 0.80

    private let doneColor =
        UIColor(
            red: 0.25,
            green: 0.90,
            blue: 0.42,
            alpha: 1
        )

    private var root =
        Entity()

    private var keys:
        Set<FPScanKey> = []

    private var count = 0

    private var lastAddAt:
        TimeInterval = 0

    func reset(
        on parent: Entity
    ) {
        root.removeFromParent()

        root = Entity()
        root.name = "scanMesh"

        keys.removeAll()
        count = 0
        lastAddAt = 0

        parent.addChild(
            root
        )
    }

    func add(
        _ source: [FPTri],
        camera: SIMD3<Float>
    ) {
        let now =
            Date()
            .timeIntervalSinceReferenceDate

        guard now - lastAddAt
                >= minAddS,
              !source.isEmpty,
              count < maxTris else {
            return
        }

        lastAddAt = now

        var fresh:
            [FPTri] = []

        fresh.reserveCapacity(
            source.count
        )

        for tri in source {
            guard count
                    + fresh.count
                    < maxTris else {
                break
            }

            let key =
                FPScanKey(
                    tri.center
                )

            guard keys.insert(
                key
            ).inserted else {
                continue
            }

            fresh.append(
                lifted(
                    tri,
                    camera: camera
                )
            )
        }

        guard !fresh.isEmpty,
              let batch =
                makeBatch(
                    fresh
                ) else {
            return
        }

        count += fresh.count

        root.addChild(
            batch
        )
    }

    private func makeBatch(
        _ tris: [FPTri]
    ) -> Entity? {
        var pos:
            [SIMD3<Float>] = []

        var idx:
            [UInt32] = []

        pos.reserveCapacity(
            tris.count * 3
        )

        idx.reserveCapacity(
            tris.count * 3
        )

        for tri in tris {
            let base =
                UInt32(
                    pos.count
                )

            pos.append(
                contentsOf: [
                    tri.a,
                    tri.b,
                    tri.c
                ]
            )

            idx.append(
                contentsOf: [
                    base,
                    base + 1,
                    base + 2
                ]
            )
        }

        var desc =
            MeshDescriptor(
                name: "scanBatch"
            )

        desc.positions =
            .init(pos)

        desc.primitives =
            .triangles(idx)

        guard let mesh =
            try? MeshResource
                .generate(
                    from: [desc]
                ) else {
            return nil
        }

        let wire =
            ModelEntity(
                mesh: mesh,
                materials: [
                    makeMat(
                        color:
                            doneColor,
                        alpha:
                            0.065
                    )
                ]
            )

        return wire
    }

    private func lifted(
        _ tri: FPTri,
        camera: SIMD3<Float>
    ) -> FPTri {
        let delta =
            camera
            - tri.center

        let length =
            simd_length(
                delta
            )

        guard length > 0.001 else {
            return tri
        }

        let offset =
            (
                delta
                / length
            )
            * liftM

        return FPTri(
            a:
                tri.a
                + offset,

            b:
                tri.b
                + offset,

            c:
                tri.c
                + offset
        )
    }

    private func makeMat(
        color: UIColor,
        alpha: Float
    ) -> UnlitMaterial {
        var mat =
            UnlitMaterial(
                color: color
            )

        mat.triangleFillMode =
            .lines

        mat.faceCulling =
            .none

        mat.readsDepth =
            true

        mat.writesDepth =
            false

        mat.blending =
            .transparent(
                opacity:
                    .init(
                        floatLiteral:
                            min(
                                max(
                                    alpha,
                                    0
                                ),
                                1
                            )
                    )
            )

        return mat
    }
}
