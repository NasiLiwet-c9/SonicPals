//
//  TargetGroundSvc.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import ARKit
import RealityKit
import simd

@MainActor
protocol TargetGroundChecking {
    func point(on plane: ARPlaneAnchor, near raw: SIMD3<Float>, session: ARSession, scene: Scene) -> SIMD3<Float>?
}

@MainActor
struct TargetGroundSvc: TargetGroundChecking {
    private let radius: Float
    private let probeH: Float
    private let maxDy: Float
    private let minSides: Int
    private let maxXZ: Float

    init(
        radius: Float = TargetCfg.Ground.checkRadius,
        probeH: Float = TargetCfg.Ground.probeHeight,
        maxDy: Float = TargetCfg.Ground.heightTolerance,
        minSides: Int = TargetCfg.Ground.minimumSideHits,
        maxXZ: Float = TargetCfg.Ground.maxHorizontalError
    ) {
        self.radius = radius
        self.probeH = probeH
        self.maxDy = maxDy
        self.minSides = minSides
        self.maxXZ = maxXZ
    }

    func point(on plane: ARPlaneAnchor, near raw: SIMD3<Float>, session: ARSession, scene: Scene) -> SIMD3<Float>? {
        guard let center = centerHit(raw, expectedY: raw.y, session: session) else { return nil }

        let points = [
            raw + SIMD3<Float>(radius, 0, 0),
            raw + SIMD3<Float>(-radius, 0, 0),
            raw + SIMD3<Float>(0, 0, radius),
            raw + SIMD3<Float>(0, 0, -radius)
        ]

        var goodSides = 0
        var ys: [Float] = [center.y]

        for point in points {
            guard let hit = sideHit(point, floorY: center.y, session: session) else { continue }
            goodSides += 1
            ys.append(hit.y)
        }

        guard goodSides >= minSides else { return nil }

        let y = ys.reduce(0, +) / Float(ys.count)
        return SIMD3<Float>(raw.x, y, raw.z)
    }

    private func centerHit(_ point: SIMD3<Float>, expectedY: Float, session: ARSession) -> SIMD3<Float>? {
        let query = ARRaycastQuery(
            origin: point + SIMD3<Float>(0, probeH, 0),
            direction: SIMD3<Float>(0, -1, 0),
            allowing: .existingPlaneGeometry,
            alignment: .horizontal
        )

        for result in session.raycast(query) {
            let pos = result.worldTransform.pos3
            guard abs(pos.y - expectedY) <= maxDy else { continue }
            guard distXZ(point, pos) <= maxXZ else { continue }
            return pos
        }

        return nil
    }

    private func sideHit(_ point: SIMD3<Float>, floorY: Float, session: ARSession) -> SIMD3<Float>? {
        let query = ARRaycastQuery(
            origin: SIMD3<Float>(point.x, floorY + probeH, point.z),
            direction: SIMD3<Float>(0, -1, 0),
            allowing: .existingPlaneGeometry,
            alignment: .horizontal
        )

        for result in session.raycast(query) {
            let pos = result.worldTransform.pos3
            guard abs(pos.y - floorY) <= maxDy else { continue }
            guard distXZ(point, pos) <= maxXZ else { continue }
            return pos
        }

        return nil
    }

    private func distXZ(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        simd_length(SIMD2<Float>(a.x - b.x, a.z - b.z))
    }
}
