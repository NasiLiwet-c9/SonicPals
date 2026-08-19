//
//  WaveModel.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import simd

enum WaveMode {
    case far
    case near
    case close
}

struct WaveSetting {
    let mode: WaveMode

    let startKHz: Float
    let endKHz: Float

    let durationMs: Float
    let waitMs: Float

    let hAngleDeg: Float
    let vAngleDeg: Float

    var midKHz: Float {
        (startKHz + endKHz) / 2
    }

    func minRange(soundSpeed: Float) -> Float {
        soundSpeed * (durationMs / 1_000) / 2
    }
}

struct WaveSet {
    let far: WaveSetting
    let near: WaveSetting
    let close: WaveSetting
    let check: WaveSetting

    let closeMaxM: Float
    let nearMaxM: Float

    func pick(_ distanceM: Float?) -> WaveSetting {
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
    static let standard = WaveSet(
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

struct WaveStart {
    let pos: SIMD3<Float>
    let forward: SIMD3<Float>
    let right: SIMD3<Float>
    let up: SIMD3<Float>
}

struct WaveRay {
    let dir: SIMD3<Float>
    let power: Float
    let sideDeg: Float
}

struct WaveHit {
    let point: SIMD3<Float>
    let normal: SIMD3<Float>
    let bounceDir: SIMD3<Float>

    let distanceM: Float
    let levelDb: Float

    let power: Float
    let sideDeg: Float
    let anglePower: Float

    let heard: Bool
}

struct WaveData {
    let start: WaveStart
    let setting: WaveSetting
    let hits: [WaveHit]

    let rayCount: Int
    let maxDistance: Float
    let soundSpeed: Float

    var hitCount: Int {
        hits.count
    }

    var echoCount: Int {
        hits.filter(\.heard).count
    }

    var nearestHit: WaveHit? {
        hits.min {
            $0.distanceM < $1.distanceM
        }
    }

    var nearestEcho: WaveHit? {
        hits
            .filter(\.heard)
            .min {
                $0.distanceM < $1.distanceM
            }
    }

    var strongestEcho: WaveHit? {
        hits
            .filter(\.heard)
            .max {
                $0.levelDb < $1.levelDb
            }
    }

    var fpRange: Float {
        maxDistance
    }
}
