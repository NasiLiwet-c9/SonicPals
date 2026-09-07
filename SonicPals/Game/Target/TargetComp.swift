//
//  TargetComp.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import Foundation
import RealityKit
import simd

/// Posted by `TargetSys` as `.targetCue` so Battiw can react
enum TargetCue {
    /// A guidance haptic fired for the first time on this tree
    case sensed

    /// The player has closed to within `TargetCfg.Cue.closeM`
    case close
}

extension Notification.Name {
    static let targetFound =
        Notification.Name("targetFound")

    static let targetCue =
        Notification.Name("targetCue")

    static let mangoEatReady =
        Notification.Name("mangoEatReady")

    static let mangoEatLost =
        Notification.Name("mangoEatLost")
}

struct TargetComp: Component {
    let real: Entity
    let parts: [TargetEchoPart]
    let lockPos: SIMD3<Float>
    let lockYaw: Float

    var seenParts: Set<Int> = []
    var pendingRevealAt: [Int: TimeInterval] = [:]
    var pulseUntil: [Int: TimeInterval] = [:]

    var found = false
    var bestM: Float?

    /// A guidance haptic has fired, enough to show the arrow even
    /// before an echo has drawn anything
    var felt = false

    /// Cues already spoken for this tree
    var saidSensed = false
    var saidClose = false

    var lastNearAt: TimeInterval = 0
    var lastDirAt: TimeInterval = 0

    var seen: Bool {
        !seenParts.isEmpty
    }
}
