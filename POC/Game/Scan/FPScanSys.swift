//
//  FPScanSys.swift
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
final class FPScanSys: System {
    static let query = EntityQuery(
        where: .has(FPScanComp.self)
    )

    static let sessQuery = EntityQuery(
        where: .has(SessComp.self)
    )

    private struct FloorHit {
        let pos: SIMD3<Float>
        let normal: SIMD3<Float>
    }

    private let sectors = 24

    private let meshTickS:
        TimeInterval = 0.45

    private let floorTickS:
        TimeInterval = 0.20

    private let estimatedFloorDelayS:
        TimeInterval = 0.75

    private let turnDelayS:
        TimeInterval = 0.85

    private let read = FPScanRead()

    private let mesh =
        FPScanMesh()

    private let floorVis =
        FPScanFloor(
            sectors: 24,
            radius: 0.90,
            width: 0.045
        )

    private var baseYaw: Float?

    private var seen:
        Set<Int> = []

    private var lastSector:
        Int?

    private var lastMeshAt:
        TimeInterval = 0

    private var lastFloorAt:
        TimeInterval = 0

    private var lastProgressAt:
        TimeInterval = 0

    private var resetAt:
        TimeInterval = 0

    private var lastReset = -1

    private var lastHUD:
        FPScanHUD?

    required init(
        scene: Scene
    ) {}

    func update(
        context: SceneUpdateContext
    ) {
        guard let session = session(
            in: context.scene
        ),
        let frame =
            session.currentFrame else {
            return
        }

        let now =
            Date()
            .timeIntervalSinceReferenceDate

        let camera =
            frame.camera.transform

        let forward =
            camForward(camera)

        let yaw =
            yaw(forward)

        for root in context.scene.performQuery(
            Self.query
        ) {
            guard var comp =
                root.components[
                    FPScanComp.self
                ] else {
                continue
            }

            if comp.resetID
                != lastReset {
                reset(
                    root: root,
                    camera: camera,
                    resetID:
                        comp.resetID,
                    now: now
                )
            }

            guard comp.active else {
                continue
            }

            if !floorVis.isPlaced,
               now - lastFloorAt
                >= floorTickS {
                lastFloorAt = now

                if let hit =
                    findFloor(
                        session: session,
                        camera: camera,
                        allowEstimated:
                            now - resetAt
                            >= estimatedFloorDelayS
                    ) {
                    floorVis.place(
                        center:
                            SIMD3<Float>(
                                camera.pos3.x,
                                hit.pos.y,
                                camera.pos3.z
                            ),
                        normal:
                            hit.normal,
                        baseYaw:
                            baseYaw
                            ?? yaw
                    )
                }
            }

            if floorVis.isPlaced {
                _ =
                    floorVis
                    .updateCursor(
                        origin:
                            camera.pos3,
                        dir:
                            forward
                    )

                floorVis
                    .updateCoverage(
                        seen: seen,
                        yaw: yaw
                    )
            }

            if now - lastMeshAt
                >= meshTickS {
                lastMeshAt = now

                let tris =
                    read.read(
                        session:
                            session,
                        camera:
                            camera,
                        limit: 420
                    )

                mesh.add(
                    tris,
                    camera:
                        camera.pos3
                )
            }

            let canCount =
                floorVis.isPlaced
                && isTracking(
                    frame.camera
                )
                && abs(
                    forward.y
                ) <= 0.72

            let turn: FPScanTurn

            if canCount {
                let index =
                    sector(
                        yaw: yaw
                    )

                markView(
                    index,
                    now: now
                )

                floorVis
                    .showHead()

                turn = turnCue(
                    from: index,
                    now: now
                )
            } else {
                floorVis
                    .hideHead()

                turn = .none
            }

            let progress =
                Float(
                    seen.count
                )
                / Float(
                    sectors
                )

            let ready =
                seen.count
                >= sectors

            post(
                FPScanHUD(
                    progress:
                        min(
                            max(
                                progress,
                                0
                            ),
                            1
                        ),
                    turn:
                        ready
                        ? .none
                        : turn,
                    ready:
                        ready
                )
            )

            if ready {
                floorVis
                    .hideHead()

                floorVis
                    .hideCursor()

                comp.active =
                    false

                root.components[
                    FPScanComp.self
                ] = comp
            }
        }
    }

    private func markView(
        _ index: Int,
        now: TimeInterval
    ) {
        let before = seen.count

        let left =
            (
                index
                - 1
                + sectors
            )
            % sectors

        let right =
            (
                index
                + 1
            )
            % sectors

        seen.insert(left)
        seen.insert(index)
        seen.insert(right)

        if let lastSector {
            let forward =
                (
                    index
                    - lastSector
                    + sectors
                )
                % sectors

            let backward =
                (
                    lastSector
                    - index
                    + sectors
                )
                % sectors

            if forward == 2 {
                seen.insert(
                    (
                        lastSector
                        + 1
                    )
                    % sectors
                )
            } else if backward == 2 {
                seen.insert(
                    (
                        lastSector
                        - 1
                        + sectors
                    )
                    % sectors
                )
            }
        }

        if seen.count > before {
            lastProgressAt = now
        }

        lastSector = index
    }

    private func turnCue(
        from index: Int,
        now: TimeInterval
    ) -> FPScanTurn {
        guard now - lastProgressAt >= turnDelayS else {
            return .none
        }

        for distance in 1..<sectors {
            let right =
                (
                    index
                    + distance
                ) % sectors

            let left =
                (
                    index
                    - distance
                    + sectors
                ) % sectors

            let needRight =
                !seen.contains(right)

            let needLeft =
                !seen.contains(left)

            if needRight && !needLeft {
                return .right
            }

            if needLeft && !needRight {
                return .left
            }

            if needRight && needLeft {
                return .right
            }
        }

        return .none
    }

    private func sector(
        yaw value: Float
    ) -> Int {
        guard let baseYaw else {
            return 0
        }

        let full =
            Float.pi * 2

        let step =
            full
            / Float(sectors)

        var delta =
            value - baseYaw

        while delta < 0 {
            delta += full
        }

        while delta >= full {
            delta -= full
        }

        let value =
            (
                delta
                + (
                    step * 0.5
                )
            )
            / step

        return Int(value)
            % sectors
    }

    private func findFloor(
        session: ARSession,
        camera: simd_float4x4,
        allowEstimated: Bool
    ) -> FloorHit? {
        let origin =
            camera.pos3

        let down =
            SIMD3<Float>(
                0,
                -1,
                0
            )

        let exact =
            ARRaycastQuery(
                origin:
                    origin,
                direction:
                    down,
                allowing:
                    .existingPlaneInfinite,
                alignment:
                    .horizontal
            )

        if let hit =
            bestFloor(
                session.raycast(
                    exact
                ),
                cameraY:
                    origin.y
            ) {
            return hit
        }

        guard allowEstimated else {
            return nil
        }

        let estimated =
            ARRaycastQuery(
                origin:
                    origin,
                direction:
                    down,
                allowing:
                    .estimatedPlane,
                alignment:
                    .horizontal
            )

        return bestFloor(
            session.raycast(
                estimated
            ),
            cameraY:
                origin.y
        )
    }

    private func bestFloor(
        _ results:
            [ARRaycastResult],
        cameraY: Float
    ) -> FloorHit? {
        results
            .compactMap {
                result
                    -> FloorHit? in

                let pos =
                    result
                    .worldTransform
                    .pos3

                let drop =
                    cameraY
                    - pos.y

                guard drop >= 0.45,
                      drop <= 2.20 else {
                    return nil
                }

                var normal =
                    SIMD3<Float>(
                        result
                            .worldTransform
                            .columns.1.x,
                        result
                            .worldTransform
                            .columns.1.y,
                        result
                            .worldTransform
                            .columns.1.z
                    )

                let length =
                    simd_length(
                        normal
                    )

                if length
                    > 0.0001 {
                    normal /=
                        length
                } else {
                    normal =
                        SIMD3<Float>(
                            0,
                            1,
                            0
                        )
                }

                if normal.y < 0 {
                    normal *= -1
                }

                return FloorHit(
                    pos: pos,
                    normal:
                        normal
                )
            }
            .min {
                $0.pos.y
                < $1.pos.y
            }
    }

    private func reset(
        root: Entity,
        camera: simd_float4x4,
        resetID: Int,
        now: TimeInterval
    ) {
        baseYaw =
            yaw(
                camForward(
                    camera
                )
            )

        seen.removeAll()
        lastSector = nil
        lastMeshAt = 0
        lastFloorAt = 0
        lastProgressAt = now
        resetAt = now
        lastReset = resetID
        lastHUD = nil

        mesh.reset(
            on: root
        )

        floorVis.reset(
            on: root
        )

        post(
            FPScanHUD(
                progress: 0,
                turn: .none,
                ready: false
            )
        )
    }

    private func yaw(
        _ forward:
            SIMD3<Float>
    ) -> Float {
        atan2(
            forward.x,
            -forward.z
        )
    }

    private func camForward(
        _ matrix:
            simd_float4x4
    ) -> SIMD3<Float> {
        simd_normalize(
            SIMD3<Float>(
                -matrix
                    .columns.2.x,
                -matrix
                    .columns.2.y,
                -matrix
                    .columns.2.z
            )
        )
    }

    private func isTracking(
        _ camera: ARCamera
    ) -> Bool {
        if case .normal =
            camera.trackingState {
            return true
        }

        return false
    }

    private func post(
        _ hud: FPScanHUD
    ) {
        guard hud
            != lastHUD else {
            return
        }

        lastHUD =
            hud

        NotificationCenter
            .default
            .post(
                name:
                    .fpScanUpdate,
                object:
                    hud
            )
    }

    private func session(
        in scene: Scene
    ) -> ARSession? {
        for entity
            in scene.performQuery(
                Self.sessQuery
            ) {
            guard let comp =
                entity.components[
                    SessComp.self
                ] else {
                continue
            }

            return comp
                .session
                .value
        }

        return nil
    }
}
