//
//  TargetSpawnSvc.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
//

import ARKit
import RealityKit
import simd

@MainActor
struct TargetSpawnSvc: TargetSpawning {
    private let minM: Float
    private let maxM: Float
    private let tries: Int

    init(
        minM: Float = 1.8,
        maxM: Float = 3.2,
        tries: Int = 18
    ) {
        self.minM = minM
        self.maxM = maxM
        self.tries = tries
    }

    func pose(
        in view: ARView,
        height: Float
    ) -> TargetPose? {
        guard let frame = view.session.currentFrame else {
            return nil
        }

        let cam = frame.camera.transform.pos3

        let planes: [ARPlaneAnchor] = frame.anchors
            .compactMap { $0 as? ARPlaneAnchor }
            .filter { $0.alignment == .horizontal }

        guard !planes.isEmpty else {
            return nil
        }

        let floors = planes.filter {
            $0.classification == .floor
        }

        let lowPlanes = planes.filter {
            $0.transform.pos3.y < cam.y - 0.55
        }

        let pool = floorPlanes(
            floors: floors,
            lowPlanes: lowPlanes
        )

        guard !pool.isEmpty else {
            return nil
        }

        var poses: [TargetPose] = []

        for plane in pool {
            for _ in 0..<tries {
                guard let pos = candidate(
                    on: plane,
                    cam: cam,
                    in: view
                ) else {
                    continue
                }

                guard hasHeadroom(
                    at: pos,
                    height: height,
                    in: view
                ) else {
                    continue
                }

                let yawRange: ClosedRange<Float> =
                    (-Float.pi)...Float.pi

                let yaw = Float.random(
                    in: yawRange
                )

                poses.append(
                    TargetPose(
                        pos: pos,
                        yaw: yaw
                    )
                )
            }
        }

        return poses.randomElement()
    }

    private func floorPlanes(
        floors: [ARPlaneAnchor],
        lowPlanes: [ARPlaneAnchor]
    ) -> [ARPlaneAnchor] {
        if !floors.isEmpty {
            return floors
        }

        let ys: [Float] = lowPlanes.map {
            $0.transform.pos3.y
        }

        guard let floorY = ys.min() else {
            return []
        }

        return lowPlanes.filter {
            abs(
                $0.transform.pos3.y - floorY
            ) <= 0.18
        }
    }

    private func candidate(
        on plane: ARPlaneAnchor,
        cam: SIMD3<Float>,
        in view: ARView
    ) -> SIMD3<Float>? {
        let pad: Float = 0.18
        let extent = plane.planeExtent

        let halfX = max(
            (extent.width * 0.5) - pad,
            0
        )

        let halfZ = max(
            (extent.height * 0.5) - pad,
            0
        )

        guard halfX > 0.12,
              halfZ > 0.12 else {
            return nil
        }

        let xRange: ClosedRange<Float> =
            (-halfX)...halfX

        let zRange: ClosedRange<Float> =
            (-halfZ)...halfZ

        let x = Float.random(
            in: xRange
        )

        let z = Float.random(
            in: zRange
        )

        let rotated = rotate(
            x: x,
            z: z,
            yaw: extent.rotationOnYAxis
        )

        let local = SIMD4<Float>(
            plane.center.x + rotated.x,
            plane.center.y,
            plane.center.z + rotated.z,
            1
        )

        let raw4 = plane.transform * local

        let raw = SIMD3<Float>(
            raw4.x,
            raw4.y,
            raw4.z
        )

        let distance = horizontalDistance(
            raw,
            cam
        )

        guard distance >= minM,
              distance <= maxM else {
            return nil
        }

        let origin = raw + SIMD3<Float>(
            0,
            0.35,
            0
        )

        let query = ARRaycastQuery(
            origin: origin,
            direction: SIMD3<Float>(
                0,
                -1,
                0
            ),
            allowing: .existingPlaneGeometry,
            alignment: .horizontal
        )

        guard let hit = view.session
            .raycast(query)
            .first
        else {
            return nil
        }

        let pos = hit.worldTransform.pos3

        guard horizontalDistance(
            pos,
            raw
        ) <= 0.22 else {
            return nil
        }

        guard abs(
            pos.y - raw.y
        ) <= 0.12 else {
            return nil
        }

        return pos
    }

    private func hasHeadroom(
        at pos: SIMD3<Float>,
        height: Float,
        in view: ARView
    ) -> Bool {
        let checkH = min(
            max(
                height * 0.78,
                0.75
            ),
            1.25
        )

        let origin = pos + SIMD3<Float>(
            0,
            0.08,
            0
        )

        let hit = view.scene.raycast(
            origin: origin,
            direction: SIMD3<Float>(
                0,
                1,
                0
            ),
            length: checkH,
            query: .nearest,
            mask: .sceneUnderstanding,
            relativeTo: nil
        )
        .first

        return hit == nil
    }

    private func rotate(
        x: Float,
        z: Float,
        yaw: Float
    ) -> (x: Float, z: Float) {
        let c = cos(yaw)
        let s = sin(yaw)

        return (
            x: (c * x) + (s * z),
            z: (-s * x) + (c * z)
        )
    }

    private func horizontalDistance(
        _ a: SIMD3<Float>,
        _ b: SIMD3<Float>
    ) -> Float {
        simd_length(
            SIMD2<Float>(
                a.x - b.x,
                a.z - b.z
            )
        )
    }
}
