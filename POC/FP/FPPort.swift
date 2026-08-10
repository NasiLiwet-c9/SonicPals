//
//  FPPort.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
//

import RealityKit
import simd

@MainActor
protocol FPMeshBuilding {
    func make(
        in view: ARView,
        from data: WaveData
    ) -> [FPMeshLayer]
}

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
