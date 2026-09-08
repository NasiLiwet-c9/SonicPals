//
//  SonarCoreTests.swift
//  SonarCore
//
//  Created by Shan Newcastle on 04/09/26.
//

import Testing
import simd

@testable import SonarCore

private let forwardStart = WaveStart(
    pos: .zero,
    forward: SIMD3<Float>(0, 0, 1),
    right: SIMD3<Float>(1, 0, 0),
    up: SIMD3<Float>(0, 1, 0)
)

/// Answers every ray with a flat wall a fixed distance straight ahead
private struct WallCaster: RayCasting {
    let distance: Float

    func cast(
        origin: SIMD3<Float>,
        direction: SIMD3<Float>,
        length: Float
    ) -> RayCastHit? {
        guard distance <= length else { return nil }

        return RayCastHit(
            position: origin + (direction * distance),
            normal: SIMD3<Float>(0, 0, -1),
            distance: distance
        )
    }
}

private struct EmptyCaster: RayCasting {
    func cast(
        origin: SIMD3<Float>,
        direction: SIMD3<Float>,
        length: Float
    ) -> RayCastHit? {
        nil
    }
}

@Suite("Acoustics")
struct EchoCalcTests {
    @Test("Level falls off as the surface gets further away")
    func levelDropsWithDistance() {
        let calc = EchoCalc()

        let close = calc.level(
            distanceM: 0.3,
            rayPower: 1,
            anglePower: 1,
            frequencyKHz: 40
        )

        let far = calc.level(
            distanceM: 1.4,
            rayPower: 1,
            anglePower: 1,
            frequencyKHz: 40
        )

        #expect(far < close)
    }

    @Test("A glancing hit reads quieter than a head-on one")
    func levelDropsWithAngle() {
        let calc = EchoCalc()

        let headOn = calc.level(
            distanceM: 0.8,
            rayPower: 1,
            anglePower: 1,
            frequencyKHz: 40
        )

        let glancing = calc.level(
            distanceM: 0.8,
            rayPower: 1,
            anglePower: 0.2,
            frequencyKHz: 40
        )

        #expect(glancing < headOn)
    }

    @Test("Anything inside the chirp's own blind zone is not heard")
    func blindZoneIsNotHeard() {
        let calc = EchoCalc()
        let setting = WaveSet.standard.far
        let blind = setting.minRange(soundSpeed: 343)

        #expect(
            !calc.heard(
                levelDb: 100,
                distanceM: blind - 0.01,
                setting: setting,
                soundSpeed: 343
            )
        )

        #expect(
            calc.heard(
                levelDb: 100,
                distanceM: blind + 0.01,
                setting: setting,
                soundSpeed: 343
            )
        )
    }

    @Test("Echo power stays inside 0.05...1")
    func powerIsClamped() {
        let calc = EchoCalc()

        #expect(calc.power(levelDb: -500) == 0.05)
        #expect(calc.power(levelDb: 500) == 1)
    }
}

@Suite("Beam shape")
struct RayMakerTests {
    @Test("Ring count decides how many rays a ping fires")
    func ringsProduceExpectedRayCount() {
        let setting = WaveSet.standard.far

        // 1 centre ray, then ring r contributes r * 8 rays
        #expect(RayMaker(rings: 0).make(for: setting).count == 1)
        #expect(RayMaker(rings: 1).make(for: setting).count == 9)
        #expect(RayMaker(rings: 2).make(for: setting).count == 25)
    }

    @Test("The centre ray carries full power and no side offset")
    func centreRayIsFullPower() throws {
        let first = try #require(RayMaker(rings: 3).make(for: WaveSet.standard.far).first)

        #expect(first.power == 1)
        #expect(first.sideDeg == 0)
        #expect(first.dir == SIMD3<Float>(0, 0, 1))
    }

    @Test("Off-axis rays are weaker than the centre ray")
    func offAxisRaysAreWeaker() {
        let rays = RayMaker(rings: 3).make(for: WaveSet.standard.far)

        #expect(rays.dropFirst().allSatisfy { $0.power < 1 })
    }
}

@Suite("Beam setting selection")
struct WaveSetTests {
    @Test(
        "Nearest surface picks the matching beam",
        arguments: [
            (Float?.none, WaveMode.far),
            (Float(0.2), WaveMode.close),
            (Float(0.8), WaveMode.near),
            (Float(2.0), WaveMode.far)
        ]
    )
    func pickMatchesDistance(distance: Float?, expected: WaveMode) {
        #expect(WaveSet.standard.pick(distance).mode == expected)
    }
}

@Suite("Simulation")
struct WaveSimTests {
    @Test("An empty room produces a ping with no hits")
    @MainActor
    func emptyRoomHasNoHits() {
        let data = WaveSim().run(using: EmptyCaster(), from: forwardStart)

        #expect(data.hitCount == 0)
        #expect(data.echoCount == 0)
        #expect(data.nearestHit == nil)
    }

    @Test("Every ray that reaches a wall comes back as a hit")
    @MainActor
    func wallIsFullyHit() {
        let sim = WaveSim(maxDistance: 1.5)

        let data = sim.run(
            using: WallCaster(distance: 1.0),
            from: forwardStart
        )

        #expect(data.hitCount == data.rayCount)
        #expect(data.nearestHit?.distanceM == 1.0)
    }

    @Test("A wall beyond max range is out of reach")
    @MainActor
    func wallBeyondRangeIsMissed() {
        let sim = WaveSim(maxDistance: 1.5)

        let data = sim.run(
            using: WallCaster(distance: 4.0),
            from: forwardStart
        )

        #expect(data.hitCount == 0)
    }

    @Test("A close wall switches the ping to the close beam")
    @MainActor
    func closeWallSelectsCloseSetting() {
        let sim = WaveSim(maxDistance: 1.5)

        let data = sim.run(
            using: WallCaster(distance: 0.3),
            from: forwardStart
        )

        #expect(data.setting.mode == .close)
    }
}

@Suite("Field classification")
struct FPClassifyTests {
    @Test(
        "Distance maps onto the colour bands",
        arguments: [
            (Float(0.2), FPBand.hot),
            (Float(0.6), FPBand.near),
            (Float(1.0), FPBand.mid),
            (Float(2.0), FPBand.far)
        ]
    )
    func bandMatchesDistance(distance: Float, expected: FPBand) {
        #expect(
            FPClassify().key(distanceM: distance, fade: 1).band == expected
        )
    }

    @Test(
        "Fade maps onto the reveal zones",
        arguments: [
            (Float(0.9), FPZone.core),
            (Float(0.4), FPZone.soft),
            (Float(0.1), FPZone.edge)
        ]
    )
    func zoneMatchesFade(fade: Float, expected: FPZone) {
        #expect(
            FPClassify().key(distanceM: 1, fade: fade).zone == expected
        )
    }
}

@Suite("Beam cone")
struct FPConeScanTests {
    private func data(maxDistance: Float = 1.5) -> WaveData {
        WaveData(
            start: forwardStart,
            setting: WaveSet.standard.far,
            hits: [],
            rayCount: 0,
            maxDistance: maxDistance,
            soundSpeed: 343
        )
    }

    @Test("A point dead ahead is inside the cone")
    func straightAheadIsInside() {
        #expect(
            FPConeScan(data: data())
                .contains(SIMD3<Float>(0, 0, 1))
        )
    }

    @Test("A point behind the camera is outside the cone")
    func behindIsOutside() {
        #expect(
            !FPConeScan(data: data())
                .contains(SIMD3<Float>(0, 0, -1))
        )
    }

    @Test("A point past max range is outside the cone")
    func beyondRangeIsOutside() {
        #expect(
            !FPConeScan(data: data(maxDistance: 1.0))
                .contains(SIMD3<Float>(0, 0, 3))
        )
    }

    @Test("Fade is strongest on the beam axis")
    func fadeIsStrongestOnAxis() throws {
        let cone = FPConeScan(data: data())

        let axis = try #require(cone.sample(SIMD3<Float>(0, 0, 1)))
        let offset = try #require(cone.sample(SIMD3<Float>(0.3, 0, 1)))

        #expect(axis.fade > offset.fade)
        #expect(axis.distanceM == 1)
    }
}

@Suite("Mesh packing")
struct FPMeshPackTests {
    private let key = FPKey(band: .hot, zone: .core)

    private func item(_ distance: Float, key: FPKey) -> FPItem {
        FPItem(
            tri: FPTri(
                a: SIMD3<Float>(0, 0, 1),
                b: SIMD3<Float>(1, 0, 1),
                c: SIMD3<Float>(0, 1, 1)
            ),
            sample: FPSample(key: key, distanceM: distance, fade: 1)
        )
    }

    @Test("Triangles sharing a key merge into one mesh")
    func sameKeyMergesIntoOneBucket() throws {
        let buckets = FPMeshPack().make(
            from: [item(1, key: key), item(2, key: key)],
            camera: .zero
        )

        let bucket = try #require(buckets[key])

        #expect(buckets.count == 1)
        #expect(bucket.pos.count == 6)
        #expect(bucket.idx == [0, 1, 2, 3, 4, 5])
    }

    @Test("Different keys land in different buckets")
    func differentKeysSplit() {
        let other = FPKey(band: .far, zone: .edge)

        let buckets = FPMeshPack().make(
            from: [item(1, key: key), item(1, key: other)],
            camera: .zero
        )

        #expect(buckets.count == 2)
    }

    @Test("A bucket remembers its nearest triangle")
    func bucketKeepsNearestDistance() throws {
        let buckets = FPMeshPack().make(
            from: [item(2.5, key: key), item(0.7, key: key)],
            camera: .zero
        )

        #expect(try #require(buckets[key].map(\.minM)) == 0.7)
    }

    @Test("Triangles are lifted toward the camera to avoid z-fighting")
    func trianglesLiftTowardCamera() throws {
        let lift: Float = 0.05
        let camera = SIMD3<Float>(0, 0, -1)

        let buckets = FPMeshPack(liftM: lift).make(
            from: [item(1, key: key)],
            camera: camera
        )

        let moved = try #require(buckets[key]?.pos.first)

        // Camera sits on -z, so lifted geometry moves toward -z
        #expect(moved.z < 1)
    }
}
