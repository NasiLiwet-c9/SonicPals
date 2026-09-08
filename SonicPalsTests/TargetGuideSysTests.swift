//
//  TargetGuideSysTests.swift
//  POCTests
//
//  Created by Shan Newcastle on 06/09/26.
//

import RealityKit
import Testing
import simd

@testable import SonicPals

/// Real entities and components, only the scene query is bypassed
@Suite("Guide arrow")
struct TargetGuideSysTests {
    private let sys = TargetGuideSys()

    private func sess(
        _ camera: simd_float4x4 = TestCamera.level(),
        teaching: Bool = false
    ) -> (camera: simd_float4x4, teaching: Bool) {
        (camera, teaching)
    }

    // MARK: - When it shows

    @Test("No arrow before the player has any sense of the tree")
    func hiddenBeforeAnySense() {
        let target = TestTarget.make()

        #expect(sys.guideBearing(targets: [target.entity], sess: sess()) == nil)
    }

    @Test("An echo that drew part of the tree earns the arrow")
    func shownOnceSeen() throws {
        let target = TestTarget.make()
        try TestTarget.setComp(target.entity) { $0.seenParts = [0] }

        #expect(sys.guideBearing(targets: [target.entity], sess: sess()) != nil)
    }

    @Test("A guidance buzz earns the arrow even with nothing drawn yet")
    func shownOnceFelt() throws {
        let target = TestTarget.make()
        try TestTarget.setComp(target.entity) { $0.felt = true }

        #expect(sys.guideBearing(targets: [target.entity], sess: sess()) != nil)
    }

    @Test("The arrow goes away once the tree is found")
    func hiddenOnceFound() throws {
        let target = TestTarget.make()
        try TestTarget.setComp(target.entity) {
            $0.seenParts = [0]
            $0.found = true
        }

        #expect(sys.guideBearing(targets: [target.entity], sess: sess()) == nil)
    }

    @Test("Nothing points anywhere while Battiw is still teaching")
    func hiddenWhileTeaching() throws {
        let target = TestTarget.make()
        try TestTarget.setComp(target.entity) { $0.seenParts = [0] }

        #expect(
            sys.guideBearing(
                targets: [target.entity],
                sess: sess(teaching: true)
            ) == nil
        )
    }

    @Test("A disabled target is ignored")
    func hiddenWhenDisabled() throws {
        let target = TestTarget.make()
        try TestTarget.setComp(target.entity) { $0.seenParts = [0] }
        target.entity.isEnabled = false

        #expect(sys.guideBearing(targets: [target.entity], sess: sess()) == nil)
    }

    @Test("With no session there is nothing to aim from")
    func hiddenWithoutSession() throws {
        let target = TestTarget.make()
        try TestTarget.setComp(target.entity) { $0.seenParts = [0] }

        #expect(sys.guideBearing(targets: [target.entity], sess: nil) == nil)
    }

    // MARK: - Where it points

    @Test(
        "The bearing matches where the tree actually is",
        arguments: [
            (SIMD3<Float>(0, 0, -2), Float(0)),          // ahead
            (SIMD3<Float>(2, 0, 0), Float.pi / 2),        // right
            (SIMD3<Float>(-2, 0, 0), -Float.pi / 2),      // left
            (SIMD3<Float>(0, 0, 2), Float.pi)             // behind
        ]
    )
    func bearingPointsAtTheTree(target: SIMD3<Float>, expected: Float) throws {
        let bearing = try #require(sys.bearing(to: target, camM: TestCamera.level()))

        #expect(abs(abs(bearing) - abs(expected)) < 0.01)

        if expected != 0, abs(expected) < Float.pi {
            #expect((bearing > 0) == (expected > 0))
        }
    }

    @Test("Height is ignored, the player walks on the floor")
    func heightIsIgnored() throws {
        let low = try #require(sys.bearing(to: SIMD3<Float>(2, 0, 0), camM: TestCamera.level()))
        let high = try #require(sys.bearing(to: SIMD3<Float>(2, 5, 0), camM: TestCamera.level()))

        #expect(abs(low - high) < 0.0001)
    }

    @Test("Standing on the tree has no direction to give")
    func noBearingOnTopOfIt() {
        #expect(sys.bearing(to: .zero, camM: TestCamera.level()) == nil)
    }

    @Test(
        "The bearing survives the phone being tilted steeply",
        arguments: [Float(0), 0.5, 1.0, 1.3, 1.5, -1.0, -1.5]
    )
    func bearingSurvivesPitch(pitch: Float) throws {
        // Flattening forward collapses near vertical
        let camM = TestCamera.posed(pitch: pitch)
        let bearing = try #require(sys.bearing(to: SIMD3<Float>(0, 0, -2), camM: camM))

        #expect(abs(bearing) < 0.01)
    }

    @Test("A steeply tilted phone still knows right from left")
    func sidesSurvivePitch() throws {
        let camM = TestCamera.posed(pitch: 1.45)
        let bearing = try #require(sys.bearing(to: SIMD3<Float>(2, 0, 0), camM: camM))

        #expect(abs(bearing - .pi / 2) < 0.01)
    }

    @Test("Heading never collapses to nothing, whatever the pitch")
    func headingStaysUsable() {
        for pitch in stride(from: Float(-1.55), through: 1.55, by: 0.1) {
            let heading = sys.heading(TestCamera.posed(pitch: pitch))

            #expect(simd_length(heading) > 0.3)
        }
    }

    // MARK: - Aiming the entity

    @Test("Aiming shows the arrow and turns it")
    func aimShowsAndTurns() throws {
        let anchor = GuideArrow.makeAnchor()
        let arrow = try #require(
            anchor.children.first { $0.components.has(GuideComp.self) }
        )
        let body = try #require(anchor.findEntity(named: GuideArrow.bodyName))

        #expect(!body.isEnabled)

        sys.aim(arrows: [arrow], bearing: .pi / 2)

        #expect(body.isEnabled)

        let up = arrow.orientation.act(SIMD3<Float>(0, 1, 0))
        #expect(up.x > 0.5)
    }

    @Test("A nil bearing hides the arrow")
    func aimHides() throws {
        let anchor = GuideArrow.makeAnchor()
        let arrow = try #require(
            anchor.children.first { $0.components.has(GuideComp.self) }
        )
        let body = try #require(anchor.findEntity(named: GuideArrow.bodyName))

        sys.aim(arrows: [arrow], bearing: 0)
        #expect(body.isEnabled)

        sys.aim(arrows: [arrow], bearing: nil)
        #expect(!body.isEnabled)
    }

    @Test("Pointing straight ahead leaves the arrow pointing up the screen")
    func aheadPointsUp() throws {
        let anchor = GuideArrow.makeAnchor()
        let arrow = try #require(
            anchor.children.first { $0.components.has(GuideComp.self) }
        )

        sys.aim(arrows: [arrow], bearing: 0)

        // The dial leans back, but must not swing left or right
        let up = arrow.orientation.act(SIMD3<Float>(0, 1, 0))
        #expect(abs(up.x) < 0.01)
        #expect(up.y > 0.5)
    }
}
