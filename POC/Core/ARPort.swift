//
//  ARPort.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

import ARKit
import RealityKit
import UIKit

@MainActor
protocol SceneControlling: AnyObject {
    var onState: ((ARState) -> Void)? { get set }
    
    func setup(_ view: ARView)
    func place()
    func sendWave()
    func turn(_ deg: Float)
    func toggleMesh()
    func togglePoints()
    func toggleView()
    func clear()
    func handleMemoryWarning()
}

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
