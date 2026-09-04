//
//  SceneRayCaster.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import RealityKit
import SonarCore
import simd

/// Satisfies `SonarCore.RayCasting` against the room mesh — the only
/// place the simulation touches RealityKit.
@MainActor
struct SceneRayCaster: RayCasting {
    private let scene: Scene

    init(scene: Scene) {
        self.scene = scene
    }

    func cast(
        origin: SIMD3<Float>,
        direction: SIMD3<Float>,
        length: Float
    ) -> RayCastHit? {
        guard let hit = scene.raycast(
            origin: origin,
            direction: direction,
            length: length,
            query: .nearest,
            mask: .sceneUnderstanding,
            relativeTo: nil
        ).first else {
            return nil
        }

        return RayCastHit(
            position: hit.position,
            normal: hit.normal,
            distance: hit.distance
        )
    }
}
