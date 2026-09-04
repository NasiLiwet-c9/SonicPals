//
//  Components.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import ARKit
import Foundation
import RealityKit
import SonarCore

/// Components are value types, so the session goes behind a weak box.
final class ARSessionRef {
    weak var value: ARSession?

    init(_ value: ARSession) {
        self.value = value
    }
}

struct SessComp: Component {
    let session: ARSessionRef
    var lidarOK = false
    var spawning = false
}

/// A faded-out ping, kept briefly so recent pings still hint at the room.
struct TraceComp: Component {
    let createdAt: TimeInterval
}

/// One ping in flight, and how far through its reveal it is.
struct RevealComp: Component {
    enum Stage {
        case waiting(attempt: Int, nextAt: TimeInterval)
        case revealing(index: Int, startedAt: TimeInterval)
        case holding(until: TimeInterval)
        case fading(zoneIndex: Int, lastAt: TimeInterval)
        case empty(until: TimeInterval)
    }

    let data: WaveData
    var layers: [FPMeshLayer] = []
    var stage: Stage = .waiting(attempt: 0, nextAt: 0)
}
