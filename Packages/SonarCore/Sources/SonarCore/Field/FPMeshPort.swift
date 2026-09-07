//
//  FPMeshPort.swift
//  SonarCore
//
//  Created by Shan Newcastle on 10/08/26.
//

import simd

/// Buckets triangles by band and zone. No rendering type crosses it
public protocol FPMeshPackPort: Sendable {
    func make(
        from items: [FPItem],
        camera: SIMD3<Float>
    ) -> [FPKey: FPMeshData]
}
