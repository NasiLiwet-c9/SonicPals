//
//  FPRevealSysTests.swift
//  POCTests
//
//  Created by Shan Newcastle on 07/09/26.
//

import ARKit
import Foundation
import RealityKit
import SonarCore
import Testing

@testable import SonicPals

/// Real entities, with a stub builder for the geometry ARKit supplies
@Suite("Reveal system")
struct FPRevealSysTests {
    private let session = ARSession()

    private func ping() -> Entity {
        let entity = Entity()
        entity.components.set(RevealComp(data: TestWave.data()))
        return entity
    }

    private func stage(_ entity: Entity) -> RevealComp.Stage? {
        entity.components[RevealComp.self]?.stage
    }

    // MARK: - Waiting for geometry

    @Test("A ping that finds geometry starts revealing it")
    func geometryStartsTheReveal() throws {
        let layers = [
            TestReveal.layer(delayMs: 70, zone: .core),
            TestReveal.layer(delayMs: 0, zone: .edge)
        ]

        let sys = FPRevealSys(mesh: StubMeshBuilder(layers: layers))
        let entity = ping()

        sys.step(entities: [entity], session: session, now: 100)

        guard case .revealing = stage(entity) else {
            Issue.record("expected revealing, got \(String(describing: stage(entity)))")
            return }

        let comp = try #require(entity.components[RevealComp.self])

        #expect(comp.layers.map(\.delayMs) == [0, 70])
        #expect(entity.children.count == 2)
    }

    @Test("Layers start hidden, pulsing, with no trace yet")
    func layersStartHidden() {
        let layer = TestReveal.layer(delayMs: 0, zone: .core)
        let sys = FPRevealSys(mesh: StubMeshBuilder(layers: [layer]))

        sys.step(entities: [ping()], session: session, now: 100)

        #expect(!layer.root.isEnabled)
        #expect(layer.pulse.isEnabled)
        #expect(!layer.trace.isEnabled)
    }

    @Test("A ping into empty air retries before giving up")
    func emptyAirRetries() {
        let builder = StubMeshBuilder(layers: [])
        let sys = FPRevealSys(mesh: builder)
        let entity = ping()

        sys.step(entities: [entity], session: session, now: 100)

        guard case let .waiting(attempt, _) = stage(entity) else {
            Issue.record("expected waiting")
            return }

        #expect(attempt == 1)
        #expect(builder.callCount == 1)
    }

    @Test("A ping that finds nothing eventually gives up")
    func emptyAirGivesUp() {
        let sys = FPRevealSys(mesh: StubMeshBuilder(layers: []))
        let entity = ping()

        for attempt in 0...3 {
            sys.step(
                entities: [entity],
                session: session,
                now: 100 + Double(attempt)
            )
        }

        guard case .empty = stage(entity) else {
            Issue.record("expected empty, got \(String(describing: stage(entity)))")
            return }
    }

    @Test("Nothing happens before the retry delay is up")
    func waitsForTheRetryDelay() {
        let builder = StubMeshBuilder(layers: [])
        let sys = FPRevealSys(mesh: builder)
        let entity = ping()
        entity.components[RevealComp.self]?.stage = .waiting(attempt: 0, nextAt: 500)

        sys.step(entities: [entity], session: session, now: 100)

        #expect(builder.callCount == 0)
    }

    @Test("Without a session there is nothing to read geometry from")
    func noSessionDoesNothing() {
        let builder = StubMeshBuilder(layers: [])
        let sys = FPRevealSys(mesh: builder)

        sys.step(entities: [ping()], session: nil, now: 100)

        #expect(builder.callCount == 0)
    }

    // MARK: - Revealing

    @Test("Layers light up as their delay comes due")
    func layersLightInOrder() {
        let near = TestReveal.layer(delayMs: 0, zone: .edge)
        let far = TestReveal.layer(delayMs: 70, zone: .core)

        let sys = FPRevealSys(mesh: StubMeshBuilder(layers: [near, far]))
        let entity = ping()

        sys.step(entities: [entity], session: session, now: 100)

        // 50ms in: the first is due, the second is not
        sys.step(entities: [entity], session: session, now: 100.05)

        #expect(near.root.isEnabled)
        #expect(!far.root.isEnabled)
    }

    @Test("Once every layer is up the ping holds")
    func fullRevealHolds() {
        let layer = TestReveal.layer(delayMs: 0, zone: .core)
        let sys = FPRevealSys(mesh: StubMeshBuilder(layers: [layer]))
        let entity = ping()

        sys.step(entities: [entity], session: session, now: 100)
        sys.step(entities: [entity], session: session, now: 100.2)

        #expect(layer.root.isEnabled)

        guard case .holding = stage(entity) else {
            Issue.record("expected holding, got \(String(describing: stage(entity)))")
            return }
    }

    // MARK: - Fading

    @Test("The hold runs out and the ping starts fading")
    func holdBecomesFade() {
        let sys = FPRevealSys(mesh: StubMeshBuilder())
        let entity = ping()
        entity.components[RevealComp.self]?.stage = .holding(until: 200)

        sys.step(entities: [entity], session: session, now: 201)

        guard case let .fading(zoneIndex, _) = stage(entity) else {
            Issue.record("expected fading")
            return }

        #expect(zoneIndex == 0)
    }

    @Test("Fading turns a zone's pulse into its lingering trace")
    func fadeLeavesATrace() {
        let core = TestReveal.layer(delayMs: 0, zone: .core)
        core.pulse.isEnabled = true

        let sys = FPRevealSys(mesh: StubMeshBuilder(layers: [core]))
        let entity = ping()

        sys.step(entities: [entity], session: session, now: 100)

        entity.components[RevealComp.self]?.stage = .fading(zoneIndex: 0, lastAt: 100)

        sys.step(entities: [entity], session: session, now: 101)

        #expect(!core.pulse.isEnabled)
        #expect(core.trace.isEnabled)
        #expect(core.root.isEnabled)
    }

    @Test("A finished ping becomes a trace the world can trim later")
    func finishedPingBecomesATrace() {
        let sys = FPRevealSys(mesh: StubMeshBuilder())
        let entity = ping()

        // Past the last zone
        entity.components[RevealComp.self]?.stage = .fading(zoneIndex: 3, lastAt: 100)

        sys.step(entities: [entity], session: session, now: 101)

        #expect(!entity.components.has(RevealComp.self))
        #expect(entity.components[TraceComp.self]?.createdAt == 101)
    }

    @Test("Fading waits out its step between zones")
    func fadeStepsAreSpaced() {
        let sys = FPRevealSys(mesh: StubMeshBuilder())
        let entity = ping()
        entity.components[RevealComp.self]?.stage = .fading(zoneIndex: 0, lastAt: 100)

        sys.step(entities: [entity], session: session, now: 100.01)

        guard case let .fading(zoneIndex, _) = stage(entity) else {
            Issue.record("expected fading")
            return }

        #expect(zoneIndex == 0)
    }

    // MARK: - Cleanup

    @Test("A ping that found nothing removes itself when its time is up")
    func emptyPingRemovesItself() {
        let sys = FPRevealSys(mesh: StubMeshBuilder())
        let parent = Entity()
        let entity = ping()
        parent.addChild(entity)

        entity.components[RevealComp.self]?.stage = .empty(until: 200)

        sys.step(entities: [entity], session: session, now: 201)

        #expect(entity.parent == nil)
        #expect(parent.children.isEmpty)
    }

    @Test("It stays put until then")
    func emptyPingWaitsItsTurn() {
        let sys = FPRevealSys(mesh: StubMeshBuilder())
        let parent = Entity()
        let entity = ping()
        parent.addChild(entity)

        entity.components[RevealComp.self]?.stage = .empty(until: 200)

        sys.step(entities: [entity], session: session, now: 150)

        #expect(entity.parent === parent)
    }
}
