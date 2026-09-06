//
//  TargetCfg.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import Foundation

nonisolated enum TargetCfg {
    enum Tree {
        static let height: Float = 1.40
        static let realDim: Float = 0.86
    }

    enum Spawn {
        static let minDistance: Float = 1.8
        static let maxDistance: Float = 3.2
        static let tries = 3
        static let minPlaneSize: Float = 0.28
        static let planeEdge: Float = 0.04
        static let repeatDistance: Float = 1.0
        static let maxPlanes = 4
        static let floorBelowCamera: Float = 0.45
        static let floorHeightBand: Float = 0.14
    }

    enum Ground {
        static let checkRadius: Float = 0.22
        static let probeHeight: Float = 0.42
        static let heightTolerance: Float = 0.08
        static let minimumSideHits = 2
        static let maxHorizontalError: Float = 0.10
    }

    enum Clearance {
        static let wallMinRadius: Float = 0.52
        static let wallMaxRadius: Float = 0.64
        static let objectMinRadius: Float = 0.48
        static let objectMaxRadius: Float = 0.60
        static let overheadRadius: Float = 0.38
        static let overheadStartPadding: Float = 0.18
        static let overheadBottomClearance: Float = 0.16
    }

    enum Echo {
        static let waveTravelS: TimeInterval = 0.85
        static let pulseHoldS: TimeInterval = 1.25

        static let treePulseAlpha: Float = 1.0
        static let treeTraceAlpha: Float = 0.16

        static let mangoPulseAlpha: Float = 0.92
        static let mangoPulseBehindAlpha: Float = 0.65

        static let mangoTraceAlpha: Float = 0.30
        static let mangoTraceBehindAlpha: Float = 0.16

        static let mangoPulseScale: Float = 1.05
        static let mangoTraceScale: Float = 1.08
        static let mangoXrayScale: Float = 1.01
    }

    enum Cue {
        static let closeM: Float = 1.6     // "It's close" distance.
    }

    enum Preflight {
        static let startProgress: Float = 0.70
        static let waitingProgress: Float = 0.95
        static let checkInterval: TimeInterval = 0.45
        static let retryMs = 500
    }
}
