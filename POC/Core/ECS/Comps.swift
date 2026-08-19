//
//  Comps.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import ARKit
import Foundation
import RealityKit

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
    var layers: [FPMeshLayer] = []
    var stage: Stage = .waiting(attempt: 0, nextAt: 0)
}
