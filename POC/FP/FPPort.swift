//
//  FPPort.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//

import RealityKit
import simd

@MainActor
protocol FPMeshReadPort {
    func read(
        in view: ARView,
        cone: FPConeScan,
        limit: Int
    ) -> [FPTri]
}

protocol FPMeshPackPort {
    func make(
        from items: [FPItem],
        camera: SIMD3<Float>
    ) -> [FPKey: FPMeshData]
}

@MainActor
protocol FPMeshMakePort {
    func make(
        from data: FPMeshData,
        key: FPKey,
        range: Float
    ) -> FPMeshLayer?
}
