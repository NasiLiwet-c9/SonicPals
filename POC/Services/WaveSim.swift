import Foundation
import RealityKit
import simd

@MainActor
final class WaveSim:
    WaveSimulating {

    private let maxDist: Float = 4
    private let recvRadius: Float = 0.12
    private let soundSpd: Float = 343
    private let gap: Float = 0.015

    func run(
        in view: ARView,
        from sensor: Entity
    ) -> WaveData {
        let source = sensor.convert(
            position: SIMD3<Float>.zero,
            to: nil
        )

        let dirs = makeDirs()

        var segs: [WaveSeg] = []
        var marks: [SIMD3<Float>] = []

        var hitCount = 0
        var echoCount = 0
        var bestPath: Float?

        for localDir in dirs {
            let dir = simd_normalize(
                sensor.convert(
                    direction: localDir,
                    to: nil
                )
            )

            let firstHits = view.scene.raycast(
                origin: source,
                direction: dir,
                length: maxDist,
                query: .nearest,
                mask: .sceneUnderstanding,
                relativeTo: nil
            )

            guard let hit = firstHits.first else {
                let end =
                    source + (dir * maxDist)

                let segment = WaveSeg(
                    start: source,
                    end: end,
                    type: .outgoing
                )

                segs.append(segment)
                continue
            }

            hitCount += 1

            let outgoing = WaveSeg(
                start: source,
                end: hit.position,
                type: .outgoing
            )

            segs.append(outgoing)
            marks.append(hit.position)

            var normal = simd_normalize(
                hit.normal
            )

            if simd_dot(
                dir,
                normal
            ) > 0 {
                normal = -normal
            }

            let dot =
                simd_dot(
                    dir,
                    normal
                )

            let refDir = simd_normalize(
                dir - (2 * dot * normal)
            )

            let refStart =
                hit.position
                + (refDir * gap)

            let freeDist = nextDist(
                in: view,
                start: refStart,
                dir: refDir
            )

            let toSensor =
                source - refStart

            let sensorDist =
                simd_dot(
                    toSensor,
                    refDir
                )

            let nearPoint =
                refStart
                + (refDir * sensorDist)

            let missDist =
                simd_length(
                    nearPoint - source
                )

            let hasEcho =
                sensorDist > 0
                && sensorDist <= freeDist
                && missDist <= recvRadius

            if hasEcho {
                echoCount += 1

                let path =
                    hit.distance
                    + sensorDist

                if let currentPath = bestPath {
                    bestPath = min(
                        currentPath,
                        path
                    )
                } else {
                    bestPath = path
                }

                let echoSeg = WaveSeg(
                    start: hit.position,
                    end: source,
                    type: .echo
                )

                segs.append(echoSeg)
            } else {
                let refEnd =
                    refStart
                    + (refDir * freeDist)

                let reflectedSeg = WaveSeg(
                    start: hit.position,
                    end: refEnd,
                    type: .reflected
                )

                segs.append(reflectedSeg)
            }
        }

        let echoMs: Float?

        if let bestPath {
            echoMs =
                (bestPath / soundSpd)
                * 1000
        } else {
            echoMs = nil
        }

        return WaveData(
            segs: segs,
            hits: marks,
            rayCount: dirs.count,
            hitCount: hitCount,
            echoCount: echoCount,
            bestPath: bestPath,
            echoMs: echoMs
        )
    }

    private func nextDist(
        in view: ARView,
        start: SIMD3<Float>,
        dir: SIMD3<Float>
    ) -> Float {
        let hits = view.scene.raycast(
            origin: start,
            direction: dir,
            length: maxDist,
            query: .all,
            mask: .sceneUnderstanding,
            relativeTo: nil
        )

        let nextHit = hits.first {
            $0.distance > 0.03
        }

        guard let nextHit else {
            return maxDist
        }

        return min(
            nextHit.distance,
            maxDist
        )
    }

    private func makeDirs()
        -> [SIMD3<Float>] {

        let angleDeg: Float = 6

        let angleRad =
            angleDeg
            * Float.pi
            / 180

        let side = Float(
            Foundation.tan(
                Double(angleRad)
            )
        )

        let center = SIMD3<Float>(
            0,
            0,
            -1
        )

        let left = simd_normalize(
            SIMD3<Float>(
                -side,
                0,
                -1
            )
        )

        let right = simd_normalize(
            SIMD3<Float>(
                side,
                0,
                -1
            )
        )

        return [
            center,
            left,
            right
        ]
    }
}
