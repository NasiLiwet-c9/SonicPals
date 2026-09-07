//
//  ScanCoverageTests.swift
//  POCTests
//
//  Created by Shan Newcastle on 05/09/26.
//

import Testing
import simd

@testable import SonicPals

@Suite("Scan coverage")
struct ScanCoverageTests {
    private func swept(sectors: Int = 8) -> ScanCoverage {
        var coverage = ScanCoverage(sectors: sectors)
        coverage.reset(baseYaw: 0, now: 0)
        return coverage
    }

    @Test("Nothing is covered before the sweep starts")
    func startsEmpty() {
        let coverage = swept()

        #expect(coverage.progress == 0)
        #expect(!coverage.isComplete)
        #expect(coverage.lastSector == nil)
    }

    @Test("Facing the start heading is sector 0")
    func baseHeadingIsSectorZero() {
        var coverage = ScanCoverage(sectors: 8)
        coverage.reset(baseYaw: 1.2, now: 0)

        #expect(coverage.sector(yaw: 1.2) == 0)
    }

    @Test("Turning a quarter circle lands a quarter of the way round")
    func sectorTracksYaw() {
        var coverage = ScanCoverage(sectors: 8)
        coverage.reset(baseYaw: 0, now: 0)

        #expect(coverage.sector(yaw: .pi / 2) == 2)
        #expect(coverage.sector(yaw: .pi) == 4)
    }

    @Test("Sectors wrap rather than running off the end")
    func sectorWraps() {
        var coverage = ScanCoverage(sectors: 8)
        coverage.reset(baseYaw: 0, now: 0)

        #expect(coverage.sector(yaw: 2 * .pi) == 0)
        #expect(coverage.sector(yaw: -.pi / 2) == 6)
    }

    @Test("Marking a sector also credits its neighbours")
    func marksNeighbours() {
        var coverage = swept()
        coverage.mark(sector: 3, now: 1)

        #expect(coverage.seen == [2, 3, 4])
        #expect(coverage.lastSector == 3)
    }

    @Test("Neighbours wrap past zero")
    func neighboursWrap() {
        var coverage = swept()
        coverage.mark(sector: 0, now: 1)

        #expect(coverage.seen == [7, 0, 1])
    }

    @Test("A sector skipped by a fast turn is filled in")
    func fillsASkippedSector() {
        var coverage = swept()
        coverage.mark(sector: 1, now: 1)
        coverage.mark(sector: 3, now: 2)

        // 2 is covered as a neighbour either way, the point is that
        // nothing between the two frames is left as a hole
        #expect(coverage.seen.isSuperset(of: [0, 1, 2, 3, 4]))
    }

    @Test("Filling works turning the other way too")
    func fillsBackwards() {
        var coverage = swept()
        coverage.mark(sector: 5, now: 1)
        coverage.mark(sector: 3, now: 2)

        #expect(coverage.seen.isSuperset(of: [2, 3, 4, 5, 6]))
    }

    @Test("Re-marking known ground does not count as progress")
    func repeatIsNotProgress() {
        var coverage = swept()
        coverage.mark(sector: 3, now: 10)

        #expect(coverage.lastProgressAt == 10)

        coverage.mark(sector: 3, now: 20)

        #expect(coverage.lastProgressAt == 10)
    }

    @Test("Progress is the fraction of sectors seen")
    func progressIsAFraction() {
        var coverage = swept(sectors: 8)
        coverage.mark(sector: 0, now: 1)

        #expect(abs(coverage.progress - 3.0 / 8.0) < 0.0001)
    }

    @Test("The sweep completes once every sector is covered")
    func completes() {
        var coverage = swept(sectors: 8)

        for sector in 0..<8 {
            coverage.mark(sector: sector, now: Double(sector))
        }

        #expect(coverage.isComplete)
        #expect(coverage.progress == 1)
    }

    @Test("No turn cue until the player has actually stalled")
    func noCueBeforeTheDelay() {
        var coverage = swept()
        coverage.mark(sector: 0, now: 0)

        #expect(coverage.turnCue(from: 0, now: 0.2, after: 0.85) == .none)
    }

    @Test("The cue points at the side that still has a gap")
    func cuePointsAtTheGap() {
        var coverage = swept(sectors: 8)
        coverage.reset(baseYaw: 0, now: 0)

        // Everything anticlockwise of 0 is covered, the gap is clockwise
        for sector in [7, 6, 5] {
            coverage.mark(sector: sector, now: 0)
        }

        #expect(coverage.turnCue(from: 0, now: 10, after: 0.85) == .right)
    }

    @Test("The cue points left when the gap is on the left")
    func cuePointsLeft() {
        var coverage = swept(sectors: 8)
        coverage.reset(baseYaw: 0, now: 0)

        for sector in [1, 2, 3] {
            coverage.mark(sector: sector, now: 0)
        }

        #expect(coverage.turnCue(from: 0, now: 10, after: 0.85) == .left)
    }

    @Test("A finished sweep asks for no more turning")
    func noCueWhenComplete() {
        var coverage = swept(sectors: 8)

        for sector in 0..<8 {
            coverage.mark(sector: sector, now: 0)
        }

        #expect(coverage.turnCue(from: 0, now: 10, after: 0.85) == .none)
    }

    @Test("Resetting clears the sweep and re-bases the heading")
    func resetClears() {
        var coverage = swept()
        coverage.mark(sector: 3, now: 1)

        coverage.reset(baseYaw: 2, now: 5)

        #expect(coverage.seen.isEmpty)
        #expect(coverage.lastSector == nil)
        #expect(coverage.lastProgressAt == 5)
        #expect(coverage.sector(yaw: 2) == 0)
    }
}

@Suite("Scan geometry")
struct ScanGeometryTests {
    @Test("A level camera faces along -Z")
    func levelForward() {
        let forward = ScanGeometry.forward(TestCamera.level())

        #expect(abs(forward.z - -1) < 0.0001)
        #expect(abs(forward.x) < 0.0001)
    }

    @Test("Yaw is zero looking down -Z and grows turning left")
    func yawFromForward() {
        #expect(abs(ScanGeometry.yaw(SIMD3<Float>(0, 0, -1))) < 0.0001)
        #expect(abs(ScanGeometry.yaw(SIMD3<Float>(1, 0, 0)) - .pi / 2) < 0.0001)
    }

    @Test(
        "A floor hit has to be plausibly below the camera",
        arguments: [
            (Float(0.0), Float(1.5), true),    // normal standing height
            (Float(1.4), Float(1.5), false),   // a desk, not the floor
            (Float(-2.0), Float(1.5), false),  // a storey down
            (Float(2.0), Float(1.5), false)    // the ceiling
        ]
    )
    func floorPlausibility(y: Float, cameraY: Float, expected: Bool) {
        #expect(ScanGeometry.isPlausibleFloor(y: y, cameraY: cameraY) == expected)
    }
}
