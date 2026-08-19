//
//  FPPort.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import ARKit
import RealityKit
import simd

@MainActor
protocol FPMeshBuilding {
    func make(
        session: ARSession,
        from data: WaveData
    ) -> [FPMeshLayer]
}

@MainActor
protocol FPMeshReadPort {
    func read(
        session: ARSession,
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
