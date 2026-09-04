//
//  RayCasting.swift
//  SonarCore
//
//  Created by Shan Newcastle on 10/08/26.
//

import simd

/// One ray/geometry intersection, in world space.
public struct RayCastHit: Sendable {
    public let position: SIMD3<Float>
    public let normal: SIMD3<Float>
    public let distance: Float

    public init(
        position: SIMD3<Float>,
        normal: SIMD3<Float>,
        distance: Float
    ) {
        self.position = position
        self.normal = normal
        self.distance = distance
    }
}

/// The one thing the simulation cannot do itself. Keeping it a port is
/// what lets the rest of `SonarCore` stay free of RealityKit.
@MainActor
public protocol RayCasting {
    func cast(
        origin: SIMD3<Float>,
        direction: SIMD3<Float>,
        length: Float
    ) -> RayCastHit?
}

@MainActor
public protocol WaveSimulating {
    func run(
        using caster: any RayCasting,
        from start: WaveStart
    ) -> WaveData
}
