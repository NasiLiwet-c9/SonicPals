//
//  TargetSpawnSvc.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import ARKit
import Foundation
import RealityKit
import SonarCore
import simd

@MainActor
struct TargetSpawnSvc: TargetSpawning {
    private let minM: Float
    private let maxM: Float
    private let tries: Int
    private let minPlaneM: Float
    private let edgeM: Float
    private let ground: any TargetGroundChecking
    private let clear: any TargetSpawnClearing

    init(
        minM: Float = TargetCfg.Spawn.minDistance,
        maxM: Float = TargetCfg.Spawn.maxDistance,
        tries: Int = TargetCfg.Spawn.tries,
        minPlaneM: Float = TargetCfg.Spawn.minPlaneSize,
        edgeM: Float = TargetCfg.Spawn.planeEdge
    ) {
        self.minM = minM
        self.maxM = maxM
        self.tries = tries
        self.minPlaneM = minPlaneM
        self.edgeM = edgeM
        ground = TargetGroundSvc()
        clear = TargetClearSvc()
    }

    init(
        minM: Float,
        maxM: Float,
        tries: Int,
        minPlaneM: Float,
        edgeM: Float,
        ground: any TargetGroundChecking,
        clear: any TargetSpawnClearing
    ) {
        self.minM = minM
        self.maxM = maxM
        self.tries = tries
        self.minPlaneM = minPlaneM
        self.edgeM = edgeM
        self.ground = ground
        self.clear = clear
    }

    func pose(session: ARSession, scene: Scene, height: Float) -> TargetPose? {
        guard let frame = session.currentFrame else {
            debug("NO FRAME")
            return nil
        }

        let camera = frame.camera.transform.pos3

        let horizontal = frame.anchors
            .compactMap { $0 as? ARPlaneAnchor }
            .filter { $0.alignment == .horizontal }

        let usablePlanes = horizontal.filter { usable($0) }

        guard !usablePlanes.isEmpty else {
            debug("NO USABLE HORIZONTAL PLANES all=\(horizontal.count)")
            return nil
        }

        let floors = usablePlanes.filter { $0.classification == .floor }

        let lowPlanes = usablePlanes.filter {
            $0.transform.pos3.y < camera.y - TargetCfg.Spawn.floorBelowCamera
        }

        let candidates = floorPlanes(floors: floors, lowPlanes: lowPlanes)

        let pool = Array(
            candidates
                .sorted { area($0) > area($1) }
                .prefix(TargetCfg.Spawn.maxPlanes)
        )

        guard !pool.isEmpty else {
            debug("NO FLOOR POOL")
            return nil
        }

        for plane in pool {
            for _ in 0..<tries {
                guard let position = candidate(
                    on: plane,
                    camera: camera,
                    session: session,
                    scene: scene
                ) else {
                    continue
                }

                guard clear.clear(
                    at: position,
                    height: height,
                    session: session,
                    scene: scene
                ) else {
                    continue
                }

                debug("POSE ACCEPTED")

                return TargetPose(
                    pos: position,
                    yaw: Float.random(in: (-Float.pi)...Float.pi)
                )
            }
        }

        debug("NO SAFE POSE FOUND")
        return nil
    }

    private func usable(_ plane: ARPlaneAnchor) -> Bool {
        let extent = plane.planeExtent
        return extent.width >= minPlaneM && extent.height >= minPlaneM
    }

    private func area(_ plane: ARPlaneAnchor) -> Float {
        plane.planeExtent.width * plane.planeExtent.height
    }

    private func floorPlanes(
        floors: [ARPlaneAnchor],
        lowPlanes: [ARPlaneAnchor]
    ) -> [ARPlaneAnchor] {
        if !floors.isEmpty { return floors }

        guard let floorY = lowPlanes.map({ $0.transform.pos3.y }).min() else { return [] }

        return lowPlanes.filter {
            abs($0.transform.pos3.y - floorY) <= TargetCfg.Spawn.floorHeightBand
        }
    }

    private func candidate(
        on plane: ARPlaneAnchor,
        camera: SIMD3<Float>,
        session: ARSession,
        scene: Scene
    ) -> SIMD3<Float>? {
        let extent = plane.planeExtent
        let halfX = max((extent.width * 0.5) - edgeM, 0)
        let halfZ = max((extent.height * 0.5) - edgeM, 0)

        guard halfX > 0.06, halfZ > 0.06 else { return nil }

        let x = Float.random(in: (-halfX)...halfX)
        let z = Float.random(in: (-halfZ)...halfZ)
        let rotated = rotate(x: x, z: z, yaw: extent.rotationOnYAxis)

        let local = SIMD4<Float>(
            plane.center.x + rotated.x,
            plane.center.y,
            plane.center.z + rotated.z,
            1
        )

        let world = plane.transform * local
        let raw = SIMD3<Float>(world.x, world.y, world.z)
        let distance = distXZ(raw, camera)

        guard distance >= minM, distance <= maxM else {
            debug(String(format: "DIST REJECT %.2fm", distance))
            return nil
        }

        guard let position = ground.point(
            on: plane,
            near: raw,
            session: session,
            scene: scene
        ) else {
            debug("GROUND REJECT")
            return nil
        }

        return position
    }

    private func rotate(x: Float, z: Float, yaw: Float) -> (x: Float, z: Float) {
        let c = cos(yaw)
        let s = sin(yaw)
        return ((c * x) + (s * z), (-s * x) + (c * z))
    }

    private func distXZ(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        simd_length(SIMD2<Float>(a.x - b.x, a.z - b.z))
    }

    private func debug(_ text: String) {
#if DEBUG
        print("[TARGET SPAWN] \(text)")
#endif
    }
}
