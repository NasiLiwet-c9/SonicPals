//
//  TargetComp.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import Foundation
import RealityKit

extension Notification.Name {
    static let targetFound =
        Notification.Name("targetFound")
    
    static let mangoEatReady =
        Notification.Name("mangoEatReady")

    static let mangoEatLost =
        Notification.Name("mangoEatLost")
}

struct TargetComp: Component {
    let real: Entity
    let parts: [TargetEchoPart]
    
    var seenParts: Set<Int> = []
    var pulseUntil: [Int: TimeInterval] = [:]
    
    var found = false
    var bestM: Float?
    
    var lastNearAt: TimeInterval = 0
    var lastDirAt: TimeInterval = 0
    
    var seen: Bool {
        !seenParts.isEmpty
    }
}
