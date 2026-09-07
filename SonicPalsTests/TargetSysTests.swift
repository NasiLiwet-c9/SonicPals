//
//  TargetSysTests.swift
//  POCTests
//
//  Created by Shan Newcastle on 06/09/26.
//

import Foundation
import RealityKit
import Testing
import simd

@testable import SonicPals

/// Real entities and components, only the scene query is bypassed
@Suite("Target system")
struct TargetSysTests {
    private let sys = TargetSys()

    private func run(
        _ entity: Entity,
        camera: simd_float4x4 = TestCamera.level(),
        teaching: Bool = false,
        now: TimeInterval = 1_000
    ) {
        sys.step(
            targets: [entity],
            camM: camera,
            teaching: teaching,
            now: now
        )
    }

    // MARK: - Echo reveal

    @Test("An echo that has come due reveals its part")
    func dueEchoReveals() {
        let target = TestTarget.make()
        TestTarget.setComp(target.entity) { $0.pendingRevealAt = [0: 500] }

        run(target.entity, now: 600)

        let comp = TestTarget.comp(target.entity)

        #expect(comp.seenParts.contains(0))
        #expect(comp.pendingRevealAt.isEmpty)
        #expect(target.parts[0].pulse.isEnabled)
        #expect(target.parts[0].trace.isEnabled)
    }

    @Test("An echo still in flight stays hidden")
    func earlyEchoWaits() {
        let target = TestTarget.make()
        TestTarget.setComp(target.entity) { $0.pendingRevealAt = [0: 900] }

        run(target.entity, now: 600)

        let comp = TestTarget.comp(target.entity)

        #expect(comp.seenParts.isEmpty)
        #expect(!target.parts[0].pulse.isEnabled)
    }

    @Test("A revealed part is scheduled to fade")
    func revealSchedulesTheFade() {
        let target = TestTarget.make()
        TestTarget.setComp(target.entity) { $0.pendingRevealAt = [0: 500] }

        run(target.entity, now: 600)

        let until = TestTarget.comp(target.entity).pulseUntil[0]

        #expect(until == 600 + TargetCfg.Echo.pulseHoldS)
    }

    @Test("A pulse past its hold fades, leaving the trace behind")
    func pulseFades() {
        let target = TestTarget.make()
        target.parts[0].pulse.isEnabled = true
        target.parts[0].trace.isEnabled = true
        TestTarget.setComp(target.entity) { $0.pulseUntil = [0: 500] }

        run(target.entity, now: 600)

        #expect(!target.parts[0].pulse.isEnabled)
        #expect(target.parts[0].trace.isEnabled)
        #expect(TestTarget.comp(target.entity).pulseUntil.isEmpty)
    }

    @Test("An echo for a part that no longer exists is dropped")
    func staleIndexIsDropped() {
        let target = TestTarget.make(partCount: 1)
        TestTarget.setComp(target.entity) { $0.pendingRevealAt = [7: 500] }

        run(target.entity, now: 600)

        let comp = TestTarget.comp(target.entity)

        #expect(comp.pendingRevealAt.isEmpty)
        #expect(comp.seenParts.isEmpty)
    }

    // MARK: - Finding the tree

    @Test("Walking up to a tree you have heard finds it")
    func closeAndSeenIsFound() {
        let spy = NotificationSpy(.targetFound)
        let target = TestTarget.make(at: SIMD3<Float>(0, 0, -0.5))
        TestTarget.setComp(target.entity) { $0.seenParts = [0] }

        run(target.entity)

        #expect(TestTarget.comp(target.entity).found)
        #expect(target.real.isEnabled)
        #expect(spy.count(of: .targetFound) == 1)
    }

    @Test("Walking through an unheard tree does not find it")
    func closeButUnheardIsNotFound() {
        let target = TestTarget.make(at: SIMD3<Float>(0, 0, -0.5))

        run(target.entity)

        #expect(!TestTarget.comp(target.entity).found)
        #expect(!target.real.isEnabled)
    }

    @Test("Hearing a tree from across the room does not find it")
    func heardButFarIsNotFound() {
        let target = TestTarget.make(at: SIMD3<Float>(0, 0, -3))
        TestTarget.setComp(target.entity) { $0.seenParts = [0] }

        run(target.entity)

        #expect(!TestTarget.comp(target.entity).found)
    }

    @Test("Finding a tree clears its echoes and shows the real thing")
    func findingClearsEchoes() {
        let target = TestTarget.make(at: SIMD3<Float>(0, 0, -0.5))
        target.parts[0].pulse.isEnabled = true

        TestTarget.setComp(target.entity) {
            $0.seenParts = [0]
            $0.pulseUntil = [0: 9_999]
            $0.pendingRevealAt = [1: 9_999]
        }

        run(target.entity)

        let comp = TestTarget.comp(target.entity)

        #expect(comp.pulseUntil.isEmpty)
        #expect(comp.pendingRevealAt.isEmpty)
        #expect(!target.parts[0].pulse.isEnabled)
        #expect(target.real.isEnabled)
    }

    @Test("A found tree is not found twice")
    func foundOnlyOnce() {
        let spy = NotificationSpy(.targetFound)
        let target = TestTarget.make(at: SIMD3<Float>(0, 0, -0.5))
        TestTarget.setComp(target.entity) { $0.seenParts = [0] }

        run(target.entity)
        run(target.entity, now: 1_001)

        #expect(spy.count(of: .targetFound) == 1)
    }

    // MARK: - Guidance

    @Test("The first buzz unlocks the arrow and says so, once")
    func firstBuzzMarksFeltAndSpeaks() {
        let spy = NotificationSpy(.targetCue)
        let target = TestTarget.make(at: SIMD3<Float>(0, 0, -3))

        // First pass records the starting distance
        run(target.entity, now: 1_000)

        // The player walks a clear step closer
        run(
            target.entity,
            camera: TestCamera.level(at: SIMD3<Float>(0, 0, -1)),
            now: 1_001
        )

        let comp = TestTarget.comp(target.entity)

        #expect(comp.felt)
        #expect(comp.saidSensed)
        #expect(spy.cues().filter { $0 == .sensed }.count == 1)
    }

    @Test("Getting closer is only rewarded when it is a real step")
    func tinyStepsDoNotBuzz() {
        let target = TestTarget.make(at: SIMD3<Float>(0, 0, -3))

        // Facing away: pointing at a tree buzzes on its own
        let away = TestCamera.posed(yaw: .pi)

        run(target.entity, camera: away, now: 1_000)

        // Well under the 0.12m step the guidance asks for
        run(
            target.entity,
            camera: TestCamera.posed(yaw: .pi, at: SIMD3<Float>(0, 0, -0.02)),
            now: 1_001
        )

        #expect(!TestTarget.comp(target.entity).felt)
    }

    @Test("Turning to face a tree within reach buzzes on its own")
    func facingATreeBuzzes() {
        let target = TestTarget.make(at: SIMD3<Float>(0, 0, -2))

        run(target.entity, now: 1_000)

        #expect(TestTarget.comp(target.entity).felt)
    }

    @Test("A tree too far away does not buzz just for being looked at")
    func facingADistantTreeIsQuiet() {
        // Beyond the 3.4m the direction guidance reaches
        let target = TestTarget.make(at: SIMD3<Float>(0, 0, -5))

        run(target.entity, now: 1_000)

        #expect(!TestTarget.comp(target.entity).felt)
    }

    @Test("Closing in on a tree you have heard says it is close, once")
    func closeCueFiresOnce() {
        let spy = NotificationSpy(.targetCue)
        let target = TestTarget.make(at: SIMD3<Float>(0, 0, -1.2))
        TestTarget.setComp(target.entity) { $0.seenParts = [0] }

        run(target.entity, now: 1_000)
        run(target.entity, now: 1_001)

        #expect(TestTarget.comp(target.entity).saidClose)
        #expect(spy.cues().filter { $0 == .close }.count == 1)
    }

    @Test("Nothing is said about a tree the player has no sense of")
    func noCloseCueWithoutSense() {
        let spy = NotificationSpy(.targetCue)
        let target = TestTarget.make(at: SIMD3<Float>(0, 0, -1.2))

        // Near it, facing away, nothing drawn
        run(target.entity, camera: TestCamera.posed(yaw: .pi), now: 1_000)

        let comp = TestTarget.comp(target.entity)

        #expect(!comp.felt)
        #expect(!comp.saidClose)
        #expect(spy.cues().isEmpty)
    }

    @Test("Guidance stays silent while Battiw is teaching")
    func teachingSilencesGuidance() {
        let spy = NotificationSpy(.targetCue)
        let target = TestTarget.make(at: SIMD3<Float>(0, 0, -1.2))
        TestTarget.setComp(target.entity) { $0.seenParts = [0] }

        run(target.entity, teaching: true, now: 1_000)
        run(target.entity, teaching: true, now: 1_001)

        let comp = TestTarget.comp(target.entity)

        #expect(!comp.felt)
        #expect(!comp.saidClose)
        #expect(spy.cues().isEmpty)
    }

    @Test("Teaching still lets an echo reveal itself")
    func teachingDoesNotBlockTheReveal() {
        let target = TestTarget.make()
        TestTarget.setComp(target.entity) { $0.pendingRevealAt = [0: 500] }

        run(target.entity, teaching: true, now: 600)

        #expect(TestTarget.comp(target.entity).seenParts.contains(0))
    }

    // MARK: - Pose

    @Test("A tree is pinned to where it was planted")
    func poseIsLocked() {
        let target = TestTarget.make(at: SIMD3<Float>(1, 0, -2))

        // Tracking drift, a stray transform
        target.entity.setPosition(SIMD3<Float>(9, 9, 9), relativeTo: nil)

        run(target.entity)

        let position = target.entity.position(relativeTo: nil)

        #expect(abs(position.x - 1) < 0.0001)
        #expect(abs(position.z - -2) < 0.0001)
    }

    @Test("A disabled target is left alone")
    func disabledIsSkipped() {
        let target = TestTarget.make()
        target.entity.isEnabled = false
        TestTarget.setComp(target.entity) { $0.pendingRevealAt = [0: 500] }

        run(target.entity, now: 600)

        #expect(TestTarget.comp(target.entity).seenParts.isEmpty)
    }
}
