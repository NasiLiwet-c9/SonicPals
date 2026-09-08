//
//  MangoEatSys.swift
//  POC
//
//  Created by Jayvin Tiya Silo on 14/08/26.
//

import ARKit
import Foundation
import RealityKit
import SonarCore
import simd

/// Posts `.mangoEatReady` when the camera is close to a mango and
/// pointed at it, `.mangoEatLost` when either stops holding
///
/// Only looks at found trees, since that is what makes the real mango
/// mesh visible. Proximity and aim are enough, no scanning needed
@MainActor
final class MangoEatSys: System {
    static let query = EntityQuery(where: .has(TargetComp.self))

    static let sessQuery = EntityQuery(where: .has(SessComp.self))

    /// Spec says ~10cm, but tracking gets noisy that close and the
    /// distance is to the mesh centre, so touching distance reads higher
    private let eatDistanceM: Float = 0.5

    /// How far off centre still counts as pointing at it
    private let eatAngleDeg: Float = 30

    /// Cached per target root, to avoid walking the hierarchy each frame
    private var mangoCache: [ObjectIdentifier: Entity] = [:]

    private var ready = false

    required init(scene: Scene) {}

    /// Scene-free init, for tests
    init() {}

    func update(context: SceneUpdateContext) {
        guard let camM = cameraMatrix(in: context.scene) else {
            return
        }

        step(
            targets: context.scene.performQuery(Self.query),
            camM: camM
        )
    }

    /// `update` once the scene has been queried
    func step(
        targets: some Sequence<Entity>,
        camM: simd_float4x4
    ) {
        var matched = false

        for entity in targets {
            guard entity.isEnabled,
                  let comp = entity.components[TargetComp.self],
                  comp.found,
                  let mango = mangoEntity(for: entity, comp: comp)
            else {
                continue
            }

            if isReady(mango: mango, camM: camM) {
                matched = true
                setReady(true, mango: mango)
                break
            }
        }

        if !matched {
            setReady(false, mango: nil)
        }
    }

    // MARK: - Ready Check

    func isReady(
        mango: Entity,
        camM: simd_float4x4
    ) -> Bool {
        let camPos = camM.pos3
        let mangoPos = mango.position(relativeTo: nil)

        guard simd_distance(camPos, mangoPos) <= eatDistanceM else {
            return false
        }

        let forward = simd_normalize(
            SIMD3<Float>(
                -camM.columns.2.x,
                -camM.columns.2.y,
                -camM.columns.2.z
            )
        )

        var toMango = mangoPos - camPos

        guard simd_length(toMango) > 0.001 else {
            // Camera is basically on it, count that as pointing
            return true
        }

        toMango = simd_normalize(toMango)

        let dot = min(max(simd_dot(forward, toMango), -1), 1)
        let deg = acos(dot) * 180 / Float.pi

        return deg <= eatAngleDeg
    }

    // MARK: - State

    private func setReady(_ value: Bool, mango: Entity?) {
        guard value != ready else {
            return
        }

        ready = value

        NotificationCenter.default.post(
            name: value ? .mangoEatReady : .mangoEatLost,
            object: mango
        )
    }

    // MARK: - Mango Lookup

    private func mangoEntity(
        for entity: Entity,
        comp: TargetComp
    ) -> Entity? {
        let key = ObjectIdentifier(entity)

        if let cached = mangoCache[key],
           cached.parent != nil {
            return cached
        }

        guard let mango = comp.real.findEntity(named: "MangoTarget") else {
            mangoCache[key] = nil
            return nil
        }

        mangoCache[key] = mango
        return mango
    }

    // MARK: - Camera

    private func cameraMatrix(
        in scene: Scene
    ) -> simd_float4x4? {
        for entity in scene.performQuery(Self.sessQuery) {
            guard let comp = entity.components[SessComp.self],
                  let frame = comp.session.value?.currentFrame
            else {
                continue
            }

            return frame.camera.transform
        }

        return nil
    }
}
