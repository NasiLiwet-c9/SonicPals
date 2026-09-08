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
    static let query = EntityQuery(where: .has(FPScanComp.self))

    static let sessQuery = EntityQuery(where: .has(SessComp.self))

    private struct FloorHit {
        let pos: SIMD3<Float>
        let normal: SIMD3<Float>
    }

    private let sectors = 24

    private let meshTickS: TimeInterval = 0.45

    private let floorTickS: TimeInterval = 0.20

    private let estimatedFloorDelayS: TimeInterval = 0.75

    private let turnDelayS: TimeInterval = 0.85

    private let read = FPScanRead()

    private let mesh = FPScanMesh()

    private let floorVis = FPScanFloor(sectors: 24, radius: 0.90, width: 0.045)

    /// Sweep coverage and the turn cue, split out so both can be tested
    /// without a live session, see `ScanCoverage`
    private var coverage = ScanCoverage(sectors: 24)

    private var lastMeshAt: TimeInterval = 0

    private var lastFloorAt: TimeInterval = 0

    private var resetAt: TimeInterval = 0

    private var lastReset = -1

    private var lastHUD: FPScanHUD?

    required init(
        scene: Scene
    ) {}

    func update(context: SceneUpdateContext) {
        guard let session = session(in: context.scene),
              let frame = session.currentFrame else {
            return
        }

        let camera = frame.camera.transform
        let forward = ScanGeometry.forward(camera)

        let sweep = Sweep(
            session: session,
            camera: camera,
            forward: forward,
            yaw: ScanGeometry.yaw(forward),
            tracking: isTracking(frame.camera),
            now: Date().timeIntervalSinceReferenceDate
        )

        for root in context.scene.performQuery(Self.query) {
            guard var comp = root.components[FPScanComp.self] else {
                continue
            }

            if comp.resetID != lastReset {
                reset(
                    root: root,
                    camera: camera,
                    resetID: comp.resetID,
                    now: sweep.now
                )
            }

            guard comp.active else {
                continue
            }

            placeFloor(sweep)
            drawFloor(sweep)
            addMesh(sweep)

            let turn = markSector(sweep)
            let ready = coverage.isComplete

            post(
                FPScanHUD(
                    progress: coverage.progress,
                    turn: ready ? .none : turn,
                    ready: ready
                )
            )

            if ready {
                floorVis.hideHead()
                floorVis.hideCursor()

                comp.active = false
                root.components[FPScanComp.self] = comp
            }
        }
    }

    /// One ARFrame's worth of camera readings, so the steps below stay
    /// short and are handed the same numbers
    private struct Sweep {
        let session: ARSession
        let camera: simd_float4x4
        let forward: SIMD3<Float>
        let yaw: Float
        let tracking: Bool
        let now: TimeInterval
    }

    /// Drops the ring on the floor once a raycast finds one
    private func placeFloor(_ sweep: Sweep) {
        guard !floorVis.isPlaced,
              sweep.now - lastFloorAt >= floorTickS else {
            return
        }

        lastFloorAt = sweep.now

        guard let hit = findFloor(
            session: sweep.session,
            camera: sweep.camera,
            allowEstimated: sweep.now - resetAt >= estimatedFloorDelayS
        ) else {
            return
        }

        floorVis.place(
            center: SIMD3<Float>(
                sweep.camera.pos3.x,
                hit.pos.y,
                sweep.camera.pos3.z
            ),
            normal: hit.normal,
            baseYaw: coverage.baseYaw ?? sweep.yaw
        )
    }

    /// Moves the cursor and repaints which sectors are done
    private func drawFloor(_ sweep: Sweep) {
        guard floorVis.isPlaced else { return }

        _ = floorVis.updateCursor(origin: sweep.camera.pos3, dir: sweep.forward)

        floorVis.updateCoverage(seen: coverage.seen, yaw: sweep.yaw)
    }

    /// Folds the newest LiDAR triangles into the scan mesh, on a timer
    private func addMesh(_ sweep: Sweep) {
        guard sweep.now - lastMeshAt >= meshTickS else { return }

        lastMeshAt = sweep.now

        let tris = read.read(
            session: sweep.session,
            camera: sweep.camera,
            limit: 420
        )

        mesh.add(tris, camera: sweep.camera.pos3)
    }

    /// Counts the sector being looked at, and asks for a turn if the
    /// player has stalled. Only counts while the ring is down, tracking
    /// is good, and the phone is not pointed at the floor or ceiling
    private func markSector(_ sweep: Sweep) -> FPScanTurn {
        let canCount = floorVis.isPlaced && sweep.tracking && abs(sweep.forward.y) <= 0.72

        guard canCount else {
            floorVis.hideHead()
            return .none
        }

        let index = coverage.sector(yaw: sweep.yaw)

        coverage.mark(sector: index, now: sweep.now)
        floorVis.showHead()

        return coverage.turnCue(
            from: index,
            now: sweep.now,
            after: turnDelayS
        )
    }

    private func findFloor(
        session: ARSession,
        camera: simd_float4x4,
        allowEstimated: Bool
    ) -> FloorHit? {
        let origin = camera.pos3

        let down = SIMD3<Float>(0, -1, 0)

        let exact =
            ARRaycastQuery(
                origin: origin,
                direction: down,
                allowing: .existingPlaneInfinite,
                alignment: .horizontal
            )

        if let hit =
            bestFloor(
                session.raycast(
                    exact
                ),
                cameraY: origin.y
            ) {
            return hit
        }

        guard allowEstimated else {
            return nil
        }

        let estimated =
            ARRaycastQuery(
                origin: origin,
                direction: down,
                allowing: .estimatedPlane,
                alignment: .horizontal
            )

        return bestFloor(
            session.raycast(
                estimated
            ),
            cameraY: origin.y
        )
    }

    private func bestFloor(
        _ results:
            [ARRaycastResult],
        cameraY: Float
    ) -> FloorHit? {
        results
            .compactMap { result -> FloorHit? in

                let pos = result
                    .worldTransform
                    .pos3

                guard ScanGeometry.isPlausibleFloor(
                    y: pos.y,
                    cameraY: cameraY
                ) else {
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

                let length = simd_length(normal)

                if length
                    > 0.0001 {
                    normal /= length
                } else {
                    normal = SIMD3<Float>(0, 1, 0)
                }

                if normal.y < 0 {
                    normal *= -1
                }

                return FloorHit(pos: pos, normal: normal)
            }
            .min {
                $0.pos.y < $1.pos.y
            }
    }

    private func reset(
        root: Entity,
        camera: simd_float4x4,
        resetID: Int,
        now: TimeInterval
    ) {
        coverage.reset(
            baseYaw: ScanGeometry.yaw(
                ScanGeometry.forward(camera)
            ),
            now: now
        )

        lastMeshAt = 0
        lastFloorAt = 0
        resetAt = now
        lastReset = resetID
        lastHUD = nil

        mesh.reset(on: root)

        floorVis.reset(on: root)

        post(
            FPScanHUD(progress: 0, turn: .none, ready: false)
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

        lastHUD = hud

        NotificationCenter
            .default
            .post(name: .fpScanUpdate, object: hud)
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
