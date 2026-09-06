//
//  MangoEatSysTests.swift
//  POCTests
//
//  Created by Shan Newcastle on 06/09/26.
//

import RealityKit
import Testing
import simd

@testable import POC

/// Real entities, the mango is found by name under the target's model,
/// exactly as in the game
@Suite("Mango eat system")
struct MangoEatSysTests {
    private func target(
        mangoAt position: SIMD3<Float>,
        found: Bool = true
    ) -> Entity {
        let made = TestTarget.make(at: .zero)

        let mango = Entity()
        mango.name = "MangoTarget"
        mango.setPosition(position, relativeTo: nil)
        made.real.addChild(mango)

        TestTarget.setComp(made.entity) { $0.found = found }

        return made.entity
    }

    private func mango(at position: SIMD3<Float>) -> Entity {
        let entity = Entity()
        entity.setPosition(position, relativeTo: nil)
        return entity
    }

    // MARK: - Reach

    @Test("A mango right in front of you is in reach")
    func closeAndAimedIsReady() {
        let sys = MangoEatSys()

        #expect(
            sys.isReady(
                mango: mango(at: SIMD3<Float>(0, 0, -0.3)),
                camM: TestCamera.level()
            )
        )
    }

    @Test("A mango across the room is not")
    func tooFarIsNotReady() {
        let sys = MangoEatSys()

        #expect(
            !sys.isReady(
                mango: mango(at: SIMD3<Float>(0, 0, -2)),
                camM: TestCamera.level()
            )
        )
    }

    @Test("A mango beside you that you are not looking at is not")
    func closeButNotAimedIsNotReady() {
        let sys = MangoEatSys()

        // In reach, but 90° off where the camera points
        #expect(
            !sys.isReady(
                mango: mango(at: SIMD3<Float>(0.3, 0, 0)),
                camM: TestCamera.level()
            )
        )
    }

    @Test("A slight turn of the head still counts as looking at it")
    func slightlyOffAxisIsStillReady() {
        let sys = MangoEatSys()

        // ~11° off centre, inside the 30° allowed
        #expect(
            sys.isReady(
                mango: mango(at: SIMD3<Float>(0.06, 0, -0.3)),
                camM: TestCamera.level()
            )
        )
    }

    @Test("Standing exactly on it counts as looking at it")
    func atTheMangoIsReady() {
        let sys = MangoEatSys()

        #expect(sys.isReady(mango: mango(at: .zero), camM: TestCamera.level()))
    }

    // MARK: - Notifications

    @Test("Coming into reach announces the mango")
    func comingIntoReachAnnounces() {
        let spy = NotificationSpy(.mangoEatReady, .mangoEatLost)
        let sys = MangoEatSys()

        sys.step(
            targets: [target(mangoAt: SIMD3<Float>(0, 0, -0.3))],
            camM: TestCamera.level()
        )

        #expect(spy.count(of: .mangoEatReady) == 1)
    }

    @Test("Staying in reach does not announce it again")
    func staysAnnouncedOnce() {
        let spy = NotificationSpy(.mangoEatReady)
        let sys = MangoEatSys()
        let entity = target(mangoAt: SIMD3<Float>(0, 0, -0.3))

        sys.step(targets: [entity], camM: TestCamera.level())
        sys.step(targets: [entity], camM: TestCamera.level())

        #expect(spy.count(of: .mangoEatReady) == 1)
    }

    @Test("Walking away gives it up")
    func walkingAwayIsLost() {
        let spy = NotificationSpy(.mangoEatReady, .mangoEatLost)
        let sys = MangoEatSys()
        let entity = target(mangoAt: SIMD3<Float>(0, 0, -0.3))

        sys.step(targets: [entity], camM: TestCamera.level())
        sys.step(
            targets: [entity],
            camM: TestCamera.level(at: SIMD3<Float>(0, 0, 5))
        )

        #expect(spy.count(of: .mangoEatReady) == 1)
        #expect(spy.count(of: .mangoEatLost) == 1)
    }

    @Test("A tree that has not been found yet offers no mango")
    func unfoundTreeIsIgnored() {
        let spy = NotificationSpy(.mangoEatReady)
        let sys = MangoEatSys()

        sys.step(
            targets: [target(mangoAt: SIMD3<Float>(0, 0, -0.3), found: false)],
            camM: TestCamera.level()
        )

        #expect(spy.count(of: .mangoEatReady) == 0)
    }

    @Test("A tree with no mango left offers nothing")
    func noMangoIsIgnored() {
        let spy = NotificationSpy(.mangoEatReady)
        let sys = MangoEatSys()
        let made = TestTarget.make(at: .zero)
        TestTarget.setComp(made.entity) { $0.found = true }

        sys.step(targets: [made.entity], camM: TestCamera.level())

        #expect(spy.count(of: .mangoEatReady) == 0)
    }

    @Test("A disabled target offers nothing")
    func disabledIsIgnored() {
        let spy = NotificationSpy(.mangoEatReady)
        let sys = MangoEatSys()
        let entity = target(mangoAt: SIMD3<Float>(0, 0, -0.3))
        entity.isEnabled = false

        sys.step(targets: [entity], camM: TestCamera.level())

        #expect(spy.count(of: .mangoEatReady) == 0)
    }
}
