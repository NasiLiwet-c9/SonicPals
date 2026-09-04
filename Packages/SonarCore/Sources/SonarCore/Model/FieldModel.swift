//
//  FieldModel.swift
//  SonarCore
//
//  Created by Shan Newcastle on 10/08/26.
//

import simd

/// Distance band an echo landed in. Drives colour.
public enum FPBand: Int, CaseIterable, Sendable {
    case hot
    case near
    case mid
    case far
}

/// How central to the beam an echo was. Drives opacity and reveal delay.
public enum FPZone: Int, CaseIterable, Sendable {
    case edge
    case soft
    case core
}

/// Everything sharing a band and zone is drawn as one mesh.
public struct FPKey: Hashable, Sendable {
    public let band: FPBand
    public let zone: FPZone

    public init(band: FPBand, zone: FPZone) {
        self.band = band
        self.zone = zone
    }
}

/// Accumulated triangles for one `FPKey`.
public struct FPMeshData: Sendable {
    public var pos: [SIMD3<Float>] = []
    public var idx: [UInt32] = []
    public var minM: Float?

    public init(
        pos: [SIMD3<Float>] = [],
        idx: [UInt32] = [],
        minM: Float? = nil
    ) {
        self.pos = pos
        self.idx = idx
        self.minM = minM
    }
}

public struct FPSample: Sendable {
    public let key: FPKey
    public let distanceM: Float
    public let fade: Float

    public init(key: FPKey, distanceM: Float, fade: Float) {
        self.key = key
        self.distanceM = distanceM
        self.fade = fade
    }
}

public struct FPTri: Sendable {
    public let a: SIMD3<Float>
    public let b: SIMD3<Float>
    public let c: SIMD3<Float>

    public init(
        a: SIMD3<Float>,
        b: SIMD3<Float>,
        c: SIMD3<Float>
    ) {
        self.a = a
        self.b = b
        self.c = c
    }

    public var center: SIMD3<Float> {
        (a + b + c) / 3
    }

    public var points: [SIMD3<Float>] {
        [
            center,
            a,
            b,
            c
        ]
    }
}

public struct FPItem: Sendable {
    public let tri: FPTri
    public let sample: FPSample

    public init(tri: FPTri, sample: FPSample) {
        self.tri = tri
        self.sample = sample
    }
}
