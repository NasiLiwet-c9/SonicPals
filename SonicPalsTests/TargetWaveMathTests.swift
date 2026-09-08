//
//  TargetWaveMathTests.swift
//  POCTests
//
//  Created by Shan Newcastle on 05/09/26.
//

import RealityKit
import SonarCore
import Testing
import simd

@testable import SonicPals

@Suite("Target wave maths")
struct TargetWaveMathTests {
    private func part(
        center: SIMD3<Float>,
        half: SIMD3<Float> = SIMD3<Float>(0.1, 0.1, 0.1),
        radius: Float = 0.15
    ) -> TargetEchoPart {
        TargetEchoPart(
            name: "part",
            pulse: .init(),
            trace: .init(),
            center: center,
            half: half,
            radius: radius,
            isMango: false
        )
    }

    @Test("A point inside the part's box is zero away from it")
    func insideIsZero() {
        let p = part(center: .zero)

        #expect(TargetWaveMath.nearestDistance(from: .zero, to: p) == 0)
    }

    @Test("Distance is measured to the nearest face, not the centre")
    func measuresToTheFace() {
        // Box spans ±0.1, so 1.0 is 0.9 from the near face
        let p = part(center: .zero)
        let d = TargetWaveMath.nearestDistance(from: SIMD3<Float>(0, 0, 1), to: p)

        #expect(abs(d - 0.9) < 0.0001)
    }

    @Test("A long branch is measured from its near end")
    func longPartMeasuresFromTheNearEnd() {
        // A branch along z measures from the end nearest you
        let p = part(
            center: SIMD3<Float>(0, 0, -2),
            half: SIMD3<Float>(0.1, 0.1, 1.5)
        )

        let d = TargetWaveMath.nearestDistance(from: .zero, to: p)

        #expect(abs(d - 0.5) < 0.0001)
    }

    @Test("Something dead ahead is inside the beam")
    func straightAheadIsInCone() {
        #expect(
            TargetWaveMath.isInCone(
                center: SIMD3<Float>(0, 0, -1),
                radius: 0.1,
                data: TestWave.data()
            )
        )
    }

    @Test("Standing on top of it counts as a hit")
    func atTheOriginIsInCone() {
        #expect(
            TargetWaveMath.isInCone(
                center: .zero,
                radius: 0.1,
                data: TestWave.data()
            )
        )
    }

    @Test("Something behind the player is outside the beam")
    func behindIsOutOfCone() {
        #expect(
            !TargetWaveMath.isInCone(
                center: SIMD3<Float>(0, 0, 2),
                radius: 0.1,
                data: TestWave.data()
            )
        )
    }

    @Test("Something far off to the side is outside the beam")
    func farOffAxisIsOutOfCone() {
        #expect(
            !TargetWaveMath.isInCone(
                center: SIMD3<Float>(5, 0, -1),
                radius: 0.1,
                data: TestWave.data()
            )
        )
    }

    @Test("The beam widens with distance")
    func coneWidensWithDistance() {
        let data = TestWave.data()

        let near = TargetWaveMath.isInCone(
            center: SIMD3<Float>(0.5, 0, -0.3),
            radius: 0.01,
            data: data
        )

        let far = TargetWaveMath.isInCone(
            center: SIMD3<Float>(0.5, 0, -3.0),
            radius: 0.01,
            data: data
        )

        #expect(!near)
        #expect(far)
    }

    @Test("A big part clips the edge of the beam a small one misses")
    func radiusWidensTheTest() {
        let data = TestWave.data()
        let center = SIMD3<Float>(0.5, 0, -0.9)

        #expect(
            !TargetWaveMath.isInCone(center: center, radius: 0.01, data: data)
        )

        #expect(
            TargetWaveMath.isInCone(center: center, radius: 0.6, data: data)
        )
    }
}
