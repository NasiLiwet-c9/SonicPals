//
//  PingCooldownTests.swift
//  POCTests
//
//  Created by Shan Newcastle on 06/09/26.
//

import Foundation
import Testing

@testable import SonicPals

@Suite("Ping cooldown")
struct PingCooldownTests {
    private let short = Duration.milliseconds(60)

    @Test("A ping is ready before anything has been fired")
    func startsReady() {
        let ping = PingCooldown(cooldown: short)

        #expect(ping.canFire(enabled: true))
        #expect(!ping.coolingDown)
        #expect(ping.progress == 0)
    }

    @Test("Firing starts the cooldown")
    func fireStartsCooldown() {
        let ping = PingCooldown(cooldown: short)

        #expect(ping.fire(enabled: true))
        #expect(ping.coolingDown)
        #expect(ping.progress == 1)
    }

    @Test("A second ping during the cooldown is refused")
    func secondShotIsRefused() {
        let ping = PingCooldown(cooldown: short)

        #expect(ping.fire(enabled: true))
        #expect(!ping.fire(enabled: true))
        #expect(!ping.canFire(enabled: true))
    }

    @Test("A disabled button never fires")
    func disabledNeverFires() {
        let ping = PingCooldown(cooldown: short)

        #expect(!ping.canFire(enabled: false))
        #expect(!ping.fire(enabled: false))
        #expect(!ping.coolingDown)
    }

    @Test("The cooldown clears on its own and lets the next ping through")
    func cooldownClears() async {
        let ping = PingCooldown(cooldown: short)

        #expect(ping.fire(enabled: true))

        await ping.waitForCooldown()

        #expect(!ping.coolingDown)
        #expect(ping.progress == 0)
        #expect(ping.fire(enabled: true))
    }

    @Test("Waiting when nothing is in flight returns straight away")
    func waitingWhenIdleIsFree() async {
        let ping = PingCooldown(cooldown: .seconds(30))

        await ping.waitForCooldown()

        #expect(!ping.coolingDown)
    }

    @Test("Holding keeps firing, one shot per cooldown")
    func holdingRepeats() async {
        let ping = PingCooldown(cooldown: short)
        var shots = 0

        let started = ContinuousClock.now

        // The loop the button runs while a finger is down
        for _ in 0..<3 {
            if ping.fire(enabled: true) {
                shots += 1
            }

            await ping.waitForCooldown()
        }

        let elapsed = started.duration(to: .now)

        #expect(shots == 3)

        // No upper bound: tests share the main actor. Three shots cannot
        // have taken less than three cooldowns
        #expect(elapsed >= short * 3)
    }

    @Test("Hammering the button without waiting only fires once")
    func hammeringDoesNotBeatTheCooldown() {
        let ping = PingCooldown(cooldown: short)
        var shots = 0

        for _ in 0..<20 where ping.fire(enabled: true) {
            shots += 1
        }

        #expect(shots == 1)
    }

    @Test("Letting go mid-cooldown does not shorten it")
    func releaseDoesNotCancelCooldown() async {
        let ping = PingCooldown(cooldown: short)

        #expect(ping.fire(enabled: true))

        // The finger lifts, but the cooldown is not a child of that task
        try? await Task.sleep(for: .milliseconds(10))

        #expect(ping.coolingDown)
        #expect(!ping.fire(enabled: true))
    }

    @Test("Reset returns it to ready")
    func resetClears() {
        let ping = PingCooldown(cooldown: .seconds(30))

        #expect(ping.fire(enabled: true))
        ping.reset()

        #expect(!ping.coolingDown)
        #expect(ping.canFire(enabled: true))
    }
}
