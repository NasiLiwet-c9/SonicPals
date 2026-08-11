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
    
    static let mangoFound =
        Notification.Name("mangoFound")
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
    
    // Mango phase
    var mangoScanCount: Int = 0
    let requiredMangoScans: Int = 3
    
    var mangoFound: Bool {
        mangoScanCount >= requiredMangoScans
    }
    var seen: Bool {
        !seenParts.isEmpty
    }
}
