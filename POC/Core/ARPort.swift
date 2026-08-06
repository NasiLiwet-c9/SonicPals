//
//  ARPort.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Shanon Newcastle on 04/08/26.
//
//  NOTE: `SceneControlling` (the old god-object protocol) is gone.
//  Scene state now lives in RealityKit Components attached to entities,
//  and behaviour lives in ECSWorld+*.swift handlers and RealityKit Systems.
//  These protocols describe the remaining *stateless* services/algorithms
//  that Systems and handlers call into — they're unchanged by the ECS move.
//

import ARKit
import RealityKit
import UIKit

@MainActor
protocol ARSessionServing {
    func start(_ view: ARView) -> Bool
    func showMesh(_ show: Bool, in view: ARView)
    func addCoach(to view: ARView)
}

@MainActor
protocol PlaceServing {
    func hit(
        in view: ARView,
        at point: CGPoint
    ) -> ARRaycastResult?
}

@MainActor
protocol WaveSimulating {
    func run(
        in view: ARView,
        from start: WaveStart
    ) -> WaveData
}

@MainActor
protocol FPConeDrawing {
    func make(
        from data: WaveData
    ) -> Entity
}

@MainActor
protocol FPMeshBuilding {
    func make(
        in view: ARView,
        from data: WaveData
    ) -> [FPMeshLayer]
}

@MainActor
protocol WaveDrawing {
    func make(
        from data: WaveData,
        showAllPoints: Bool
    ) -> Entity
}
