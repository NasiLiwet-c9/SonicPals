//
//  FPMeshPack.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
//

import simd

struct FPMeshPack: FPMeshPackPort {
    private let liftM: Float

    init(liftM: Float = 0.018) {
        self.liftM = liftM
    }

    func make(
        from items: [FPItem],
        camera: SIMD3<Float>
    ) -> [FPKey: FPMeshData] {
        var buckets:
            [FPKey: FPMeshData] = [:]

        for item in items {
            let tri = lift(
                item.tri,
                camera: camera
            )

            var data =
                buckets[item.sample.key]
                ?? FPMeshData()

            add(
                tri,
                distanceM:
                    item.sample.distanceM,
                to: &data
            )

            buckets[item.sample.key] = data
        }

        return buckets
    }

    private func lift(
        _ tri: FPTri,
        camera: SIMD3<Float>
    ) -> FPTri {
        let delta =
            camera - tri.center

        let length =
            simd_length(delta)

        guard length > 0.001 else {
            return tri
        }

        let offset =
            (delta / length)
            * liftM

        return FPTri(
            a: tri.a + offset,
            b: tri.b + offset,
            c: tri.c + offset
        )
    }

    private func add(
        _ tri: FPTri,
        distanceM: Float,
        to data: inout FPMeshData
    ) {
        let base =
            UInt32(data.pos.count)

        data.pos.append(
            contentsOf: [
                tri.a,
                tri.b,
                tri.c
            ]
        )

        data.idx.append(
            contentsOf: [
                base,
                base + 1,
                base + 2
            ]
        )

        data.minM =
            min(
                data.minM ?? distanceM,
                distanceM
            )
    }
}
