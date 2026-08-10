//
//  Comps.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
//

import ARKit
import Foundation
import RealityKit

final class ARViewRef {
    weak var value: ARView?

    init(_ value: ARView) {
        self.value = value
    }
}

struct SessComp: Component {
    var lidarOK = false
    var spawning = false
}

struct TraceComp: Component {
    let createdAt: TimeInterval
}

struct RevealComp: Component {
    enum Stage {
        case waiting(attempt: Int, nextAt: TimeInterval)
        case revealing(index: Int, startedAt: TimeInterval)
        case holding(until: TimeInterval)
        case fading(zoneIndex: Int, lastAt: TimeInterval)
        case empty(until: TimeInterval)
    }

    let data: WaveData
    let view: ARViewRef

    var layers: [FPMeshLayer] = []

    var stage: Stage = .waiting(
        attempt: 0,
        nextAt: 0
    )
}
