//
//  TargetCfgTests.swift
//  POCTests
//
//  Created by Shan Newcastle on 05/09/26.
//

import Testing

@testable import POC

/// Relationships that have to hold, rather than the literals restated
@Suite("Target config")
struct TargetCfgTests {
    @Test("A tree is a plausible size")
    func treeSize() {
        #expect(TargetCfg.Tree.height > 0.5)
        #expect(TargetCfg.Tree.height < 3)
        #expect(TargetCfg.Tree.realDim > 0)
        #expect(TargetCfg.Tree.realDim <= 1)
    }

    @Test("Spawn distances make a usable band")
    func spawnBand() {
        #expect(TargetCfg.Spawn.minDistance < TargetCfg.Spawn.maxDistance)
        #expect(TargetCfg.Spawn.minDistance > 0)
        #expect(TargetCfg.Spawn.tries >= 1)
        #expect(TargetCfg.Spawn.maxPlanes >= 1)
    }

    @Test("A respawn cannot legally land back on the old spot")
    func repeatDistanceIsMeaningful() {
        #expect(TargetCfg.Spawn.repeatDistance > 0)
        #expect(TargetCfg.Spawn.repeatDistance < TargetCfg.Spawn.maxDistance)
    }

    @Test("Clearance radii are ordered min before max")
    func clearanceOrdering() {
        #expect(TargetCfg.Clearance.wallMinRadius < TargetCfg.Clearance.wallMaxRadius)
        #expect(TargetCfg.Clearance.objectMinRadius < TargetCfg.Clearance.objectMaxRadius)
        #expect(TargetCfg.Clearance.overheadRadius > 0)
    }

    @Test("A pulse outlives the echo's travel time")
    func pulseOutlivesTravel() {
        // Otherwise a part fades before its own echo arrives
        #expect(TargetCfg.Echo.pulseHoldS > TargetCfg.Echo.waveTravelS)
        #expect(TargetCfg.Echo.waveTravelS > 0)
    }

    @Test(
        "Every echo alpha is a legal opacity",
        arguments: [
            TargetCfg.Echo.treePulseAlpha,
            TargetCfg.Echo.treeTraceAlpha,
            TargetCfg.Echo.mangoPulseAlpha,
            TargetCfg.Echo.mangoPulseBehindAlpha,
            TargetCfg.Echo.mangoTraceAlpha,
            TargetCfg.Echo.mangoTraceBehindAlpha
        ]
    )
    func alphasAreOpacities(alpha: Float) {
        #expect(alpha >= 0)
        #expect(alpha <= 1)
    }

    @Test("A pulse always reads stronger than the trace it leaves")
    func pulseBeatsTrace() {
        #expect(TargetCfg.Echo.treePulseAlpha > TargetCfg.Echo.treeTraceAlpha)
        #expect(TargetCfg.Echo.mangoPulseAlpha > TargetCfg.Echo.mangoTraceAlpha)
    }

    @Test("Something behind the tree reads fainter than something in front")
    func behindIsFainter() {
        #expect(TargetCfg.Echo.mangoPulseBehindAlpha < TargetCfg.Echo.mangoPulseAlpha)
        #expect(TargetCfg.Echo.mangoTraceBehindAlpha < TargetCfg.Echo.mangoTraceAlpha)
    }

    @Test("The close cue fires inside the spawn range, not outside it")
    func closeCueIsReachable() {
        #expect(TargetCfg.Cue.closeM > 0)
        #expect(TargetCfg.Cue.closeM < TargetCfg.Spawn.maxDistance)
    }

    @Test("Preflight progress thresholds run in order and stay under 1")
    func preflightProgress() {
        #expect(TargetCfg.Preflight.startProgress > 0)
        #expect(TargetCfg.Preflight.startProgress < TargetCfg.Preflight.waitingProgress)
        #expect(TargetCfg.Preflight.waitingProgress < 1)
        #expect(TargetCfg.Preflight.retryMs > 0)
    }
}
