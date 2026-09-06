//
//  WorldWaveTests.swift
//  POCTests
//
//  Created by Shan Newcastle on 07/09/26.
//

import Foundation
import RealityKit
import SonarCore
import Testing
import simd

@testable import POC

@Suite("World waves")
struct WorldWaveTests {
    private let world = ECSWorld()

    private func trace(at time: TimeInterval) -> Entity {
        let entity = Entity()
        entity.components.set(TraceComp(createdAt: time))
        world.anchor.addChild(entity)
        return entity
    }

    // MARK: - Where a ping starts

    @Test("A ping leaves from just in front of the camera")
    func pingStartsAheadOfTheCamera() {
        let start = world.camStart(from: TestCamera.level())

        // Off the lens, so the player never counts as a hit
        #expect(start.pos.z < 0)
        #expect(start.pos.y < 0)
        #expect(simd_length(start.pos) < 0.3)
    }

    @Test("A ping is aimed where the camera is aimed")
    func pingFacesTheCamera() {
        let start = world.camStart(from: TestCamera.level())

        #expect(abs(start.forward.z - -1) < 0.0001)
        #expect(abs(start.right.x - 1) < 0.0001)
        #expect(abs(start.up.y - 1) < 0.0001)
    }

    @Test("Turning the phone turns the ping with it")
    func pingFollowsTheTurn() {
        let start = world.camStart(from: TestCamera.posed(yaw: .pi / 2))

        #expect(abs(start.forward.x - -1) < 0.001)
    }

    @Test("The ping's axes stay a proper frame")
    func axesStayOrthonormal() {
        let start = world.camStart(from: TestCamera.posed(yaw: 0.7, pitch: -0.4))

        #expect(abs(simd_length(start.forward) - 1) < 0.0001)
        #expect(abs(simd_length(start.right) - 1) < 0.0001)
        #expect(abs(simd_length(start.up) - 1) < 0.0001)
        #expect(abs(simd_dot(start.forward, start.right)) < 0.0001)
        #expect(abs(simd_dot(start.forward, start.up)) < 0.0001)
    }

    @Test("The ping starts from where the player is standing")
    func pingStartsAtThePlayer() {
        let at = SIMD3<Float>(3, 1, -2)
        let start = world.camStart(from: TestCamera.level(at: at))

        #expect(simd_distance(start.pos, at) < 0.3)
    }

    // MARK: - Firing

    @Test("Firing a ping puts it in the world")
    func showFPAddsAPing() {
        let before = world.anchor.children.count

        world.showFP(TestWave.data())

        #expect(world.anchor.children.count == before + 1)

        let added = world.anchor.children.filter {
            $0.components.has(RevealComp.self)
        }

        #expect(added.count == 1)
    }

    // MARK: - Trimming

    @Test("Recent pings are kept")
    func recentTracesAreKept() {
        _ = trace(at: 1)
        _ = trace(at: 2)

        world.trimTraces(max: 3)

        #expect(world.anchor.children.filter {
            $0.components.has(TraceComp.self)
        }.count == 2)
    }

    @Test("Older pings are trimmed away, newest kept")
    func oldTracesAreTrimmed() {
        let oldest = trace(at: 1)
        _ = trace(at: 2)
        let newest = trace(at: 3)

        world.trimTraces(max: 2)

        let left = world.anchor.children.filter {
            $0.components.has(TraceComp.self)
        }

        #expect(left.count == 2)
        #expect(oldest.parent == nil)
        #expect(newest.parent != nil)
    }

    @Test("Trimming leaves everything that is not a trace alone")
    func trimmingSparesTheRest() {
        let before = world.anchor.children.count

        for time in 1...5 {
            _ = trace(at: TimeInterval(time))
        }

        world.trimTraces(max: 1)

        let traces = world.anchor.children.filter {
            $0.components.has(TraceComp.self)
        }

        #expect(traces.count == 1)
        #expect(world.anchor.children.count == before + 1)
    }

    // MARK: - Clearing

    @Test("Clearing takes down the pings and the tree")
    func clearRemovesPingsAndTarget() {
        world.showFP(TestWave.data())
        _ = trace(at: 1)

        world.clear()

        #expect(world.anchor.children.allSatisfy {
            !$0.components.has(RevealComp.self)
                && !$0.components.has(TraceComp.self)
        })

        #expect(world.targetEntity == nil)
        #expect(!world.model.hasTarget)
        #expect(!world.model.targetFound)
    }
}
