//
//  WaveModel.swift
//  SonarCore
//
//  Created by Shan Newcastle on 10/08/26.
//

import simd

/// Beam shape for one ping, picked from how close the nearest surface is.
public enum WaveMode: Sendable {
    case far
    case near
    case close
}

public struct WaveSetting: Sendable {
    public let mode: WaveMode

    public let startKHz: Float
    public let endKHz: Float

    public let durationMs: Float
    public let waitMs: Float

    public let hAngleDeg: Float
    public let vAngleDeg: Float

    public init(
        mode: WaveMode,
        startKHz: Float,
        endKHz: Float,
        durationMs: Float,
        waitMs: Float,
        hAngleDeg: Float,
        vAngleDeg: Float
    ) {
        self.mode = mode
        self.startKHz = startKHz
        self.endKHz = endKHz
        self.durationMs = durationMs
        self.waitMs = waitMs
        self.hAngleDeg = hAngleDeg
        self.vAngleDeg = vAngleDeg
    }

    public var midKHz: Float {
        (startKHz + endKHz) / 2
    }

    /// Closer than this returns while the chirp is still emitting, so it
    /// cannot be heard as a separate echo.
    public func minRange(soundSpeed: Float) -> Float {
        soundSpeed * (durationMs / 1_000) / 2
    }
}

public struct WaveSet: Sendable {
    public let far: WaveSetting
    public let near: WaveSetting
    public let close: WaveSetting
    public let check: WaveSetting

    public let closeMaxM: Float
    public let nearMaxM: Float

    public init(
        far: WaveSetting,
        near: WaveSetting,
        close: WaveSetting,
        check: WaveSetting,
        closeMaxM: Float,
        nearMaxM: Float
    ) {
        self.far = far
        self.near = near
        self.close = close
        self.check = check
        self.closeMaxM = closeMaxM
        self.nearMaxM = nearMaxM
    }

    public func pick(_ distanceM: Float?) -> WaveSetting {
        guard let distanceM else {
            return far
        }

        if distanceM < closeMaxM {
            return close
        }

        if distanceM < nearMaxM {
            return near
        }

        return far
    }
}

extension WaveSet {
    public static let standard = WaveSet(
        far: WaveSetting(
            mode: .far,
            startKHz: 60,
            endKHz: 25,
            durationMs: 6,
            waitMs: 100,
            hAngleDeg: 22,
            vAngleDeg: 16
        ),
        near: WaveSetting(
            mode: .near,
            startKHz: 70,
            endKHz: 30,
            durationMs: 3,
            waitMs: 40,
            hAngleDeg: 24,
            vAngleDeg: 18
        ),
        close: WaveSetting(
            mode: .close,
            startKHz: 80,
            endKHz: 30,
            durationMs: 1,
            waitMs: 10,
            hAngleDeg: 26,
            vAngleDeg: 20
        ),
        check: WaveSetting(
            mode: .far,
            startKHz: 60,
            endKHz: 25,
            durationMs: 6,
            waitMs: 100,
            hAngleDeg: 24,
            vAngleDeg: 18
        ),
        closeMaxM: 0.55,
        nearMaxM: 1.05
    )
}

/// The pose a ping was fired from.
public struct WaveStart: Sendable {
    public let pos: SIMD3<Float>
    public let forward: SIMD3<Float>
    public let right: SIMD3<Float>
    public let up: SIMD3<Float>

    public init(
        pos: SIMD3<Float>,
        forward: SIMD3<Float>,
        right: SIMD3<Float>,
        up: SIMD3<Float>
    ) {
        self.pos = pos
        self.forward = forward
        self.right = right
        self.up = up
    }
}

public struct WaveRay: Sendable {
    public let dir: SIMD3<Float>
    public let power: Float
    public let sideDeg: Float

    public init(
        dir: SIMD3<Float>,
        power: Float,
        sideDeg: Float
    ) {
        self.dir = dir
        self.power = power
        self.sideDeg = sideDeg
    }
}

public struct WaveHit: Sendable {
    public let point: SIMD3<Float>
    public let normal: SIMD3<Float>
    public let bounceDir: SIMD3<Float>

    public let distanceM: Float
    public let levelDb: Float

    public let power: Float
    public let sideDeg: Float
    public let anglePower: Float

    public let heard: Bool

    public init(
        point: SIMD3<Float>,
        normal: SIMD3<Float>,
        bounceDir: SIMD3<Float>,
        distanceM: Float,
        levelDb: Float,
        power: Float,
        sideDeg: Float,
        anglePower: Float,
        heard: Bool
    ) {
        self.point = point
        self.normal = normal
        self.bounceDir = bounceDir
        self.distanceM = distanceM
        self.levelDb = levelDb
        self.power = power
        self.sideDeg = sideDeg
        self.anglePower = anglePower
        self.heard = heard
    }
}

/// Everything one ping produced — the hand-off to whatever draws it.
public struct WaveData: Sendable {
    public let start: WaveStart
    public let setting: WaveSetting
    public let hits: [WaveHit]

    public let rayCount: Int
    public let maxDistance: Float
    public let soundSpeed: Float

    public init(
        start: WaveStart,
        setting: WaveSetting,
        hits: [WaveHit],
        rayCount: Int,
        maxDistance: Float,
        soundSpeed: Float
    ) {
        self.start = start
        self.setting = setting
        self.hits = hits
        self.rayCount = rayCount
        self.maxDistance = maxDistance
        self.soundSpeed = soundSpeed
    }

    public var hitCount: Int {
        hits.count
    }

    public var echoCount: Int {
        hits.filter(\.heard).count
    }

    public var nearestHit: WaveHit? {
        hits.min {
            $0.distanceM < $1.distanceM
        }
    }

    public var nearestEcho: WaveHit? {
        hits
            .filter(\.heard)
            .min {
                $0.distanceM < $1.distanceM
            }
    }

    public var strongestEcho: WaveHit? {
        hits
            .filter(\.heard)
            .max {
                $0.levelDb < $1.levelDb
            }
    }

    /// How far the reveal mesh may reach for this ping.
    public var fpRange: Float {
        maxDistance
    }
}
