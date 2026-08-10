//
//  TargetComp.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
//

import Foundation
import RealityKit

extension Notification.Name {
    static let targetFound =
        Notification.Name(
            "targetFound"
        )
}

struct TargetComp: Component {
    let real: Entity
    let parts: [TargetEchoPart]
    let view: ARViewRef

    var seenParts: Set<Int> = []

    var pulseUntil:
        [Int: TimeInterval] = [:]

    var found = false
    var bestM: Float?

    var lastNearAt:
        TimeInterval = 0

    var lastDirAt:
        TimeInterval = 0

    var seen: Bool {
        !seenParts.isEmpty
    }
}
