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

/// Watches how close the camera is to the mango and whether it's
/// actually pointed at it. When both hold, posts `.mangoEatReady`
/// (with the mango `Entity` as `object`) so the UI can swap the wave
/// button for an "eat" button. When either stops holding — or the
/// mango is gone (already eaten) — posts `.mangoEatLost`.
///
/// Only considers a target once its tree has been found
/// (`comp.found`), since that's what makes the real mango mesh
/// visible in the scene (see `TargetSys`). Eating no longer requires
/// separately "scanning" the mango — proximity + aim is enough.
@MainActor
final class MangoEatSys: System {
    static let query = EntityQuery(
        where: .has(TargetComp.self)
    )

    static let sessQuery = EntityQuery(
        where: .has(SessComp.self)
    )

    /// "~10cm" from the spec — loosened a bit in practice. At true
    /// 10-12cm, ARKit's camera-pose tracking gets noisy (little
    /// usable feature area that close to a surface), and the
    /// measured distance is to the mesh's *visual* center (see
    /// `isReady`), not a fixed point on its surface, so real-world
    /// "touching distance" reads higher than expected. 0.28m tested
    /// as a much more reliable "right up close to it" trigger — see
    /// `logDistance` below if this needs re-tuning.
    private let eatDistanceM: Float = 0.5

    /// How far off dead-center the camera can be while still
    /// counting as "pointing at" the mango.
    private let eatAngleDeg: Float = 30

    /// Cached "MangoTarget" lookup per target root, so we don't walk
    /// the scene hierarchy every frame.
    private var mangoCache: [ObjectIdentifier: Entity] = [:]

    private var ready = false

    required init(scene: Scene) {}

    func update(context: SceneUpdateContext) {
        guard let camM = cameraMatrix(in: context.scene) else {
            return
        }

        var matched = false

        for entity in context.scene.performQuery(Self.query) {
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

    private func isReady(
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
            // Camera is (almost) exactly at the mango's position;
            // treat that as "pointing at it" by default.
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
