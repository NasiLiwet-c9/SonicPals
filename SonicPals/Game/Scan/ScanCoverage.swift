//
//  ScanCoverage.swift
//  POC
//
//  Created by Shan Newcastle on 05/09/26.
//

import Foundation
import simd

/// How much of the room is swept, and which way to send the player next
///
/// Split from `FPScanSys`, which needs an `ARFrame` to test
struct ScanCoverage {
    let sectors: Int

    /// Sector 0 is centred on the heading the sweep started from
    private(set) var baseYaw: Float?

    private(set) var seen: Set<Int> = []
    private(set) var lastSector: Int?
    private(set) var lastProgressAt: TimeInterval = 0

    init(sectors: Int = 24) {
        self.sectors = max(sectors, 1)
    }

    var progress: Float {
        min(max(Float(seen.count) / Float(sectors), 0), 1)
    }

    var isComplete: Bool {
        seen.count >= sectors
    }

    mutating func reset(baseYaw: Float, now: TimeInterval) {
        self.baseYaw = baseYaw
        seen.removeAll()
        lastSector = nil
        lastProgressAt = now
    }

    func sector(yaw value: Float) -> Int {
        guard let baseYaw else {
            return 0
        }

        let full = Float.pi * 2
        let step = full / Float(sectors)

        var delta = value - baseYaw

        while delta < 0 {
            delta += full
        }

        while delta >= full {
            delta -= full
        }

        return Int((delta + (step * 0.5)) / step) % sectors
    }

    /// Marks a sector and its neighbours. A fast turn can skip one
    /// between frames, so a gap of two is filled in
    mutating func mark(sector index: Int, now: TimeInterval) {
        let before = seen.count

        seen.insert((index - 1 + sectors) % sectors)
        seen.insert(index)
        seen.insert((index + 1) % sectors)

        if let lastSector {
            let forward = (index - lastSector + sectors) % sectors
            let backward = (lastSector - index + sectors) % sectors

            if forward == 2 {
                seen.insert((lastSector + 1) % sectors)
            } else if backward == 2 {
                seen.insert((lastSector - 1 + sectors) % sectors)
            }
        }

        if seen.count > before {
            lastProgressAt = now
        }

        lastSector = index
    }

    /// Which way to nudge once progress has stalled. Ties break right
    func turnCue(
        from index: Int,
        now: TimeInterval,
        after delay: TimeInterval
    ) -> FPScanTurn {
        guard now - lastProgressAt >= delay else {
            return .none
        }

        for distance in 1..<sectors {
            let right = (index + distance) % sectors
            let left = (index - distance + sectors) % sectors

            let needRight = !seen.contains(right)
            let needLeft = !seen.contains(left)

            if needRight && !needLeft {
                return .right
            }

            if needLeft && !needRight {
                return .left
            }

            if needRight && needLeft {
                return .right
            }
        }

        return .none
    }
}

/// Camera geometry the scan needs, without a session
enum ScanGeometry {
    static func forward(_ matrix: simd_float4x4) -> SIMD3<Float> {
        simd_normalize(
            SIMD3<Float>(
                -matrix.columns.2.x,
                -matrix.columns.2.y,
                -matrix.columns.2.z
            )
        )
    }

    static func yaw(_ forward: SIMD3<Float>) -> Float {
        atan2(forward.x, -forward.z)
    }

    /// Not the ceiling, and not the desk the phone is resting on
    static func isPlausibleFloor(
        y: Float,
        cameraY: Float,
        minDrop: Float = 0.45,
        maxDrop: Float = 2.20
    ) -> Bool {
        let drop = cameraY - y
        return drop >= minDrop && drop <= maxDrop
    }
}
