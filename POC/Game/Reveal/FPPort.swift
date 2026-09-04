//
//  FPPort.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import ARKit
import RealityKit
import SonarCore
import simd

/// Turns one ping into the layered mesh the reveal system animates.
@MainActor
protocol FPMeshBuilding {
    func make(
        session: ARSession,
        from data: WaveData
    ) -> [FPMeshLayer]
}

/// Pulls candidate triangles out of the ARKit room mesh.
@MainActor
protocol FPMeshReadPort {
    func read(
        session: ARSession,
        cone: FPConeScan,
        limit: Int
    ) -> [FPTri]
}

/// Turns one packed bucket into a drawable layer.
@MainActor
protocol FPMeshMakePort {
    func make(
        from data: FPMeshData,
        key: FPKey,
        range: Float
    ) -> FPMeshLayer?
}
