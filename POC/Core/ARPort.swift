//
//  ARPort.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Shanon Newcastle on 03/08/26.
//

import ARKit
import RealityKit
import UIKit

@MainActor
protocol SceneControlling: AnyObject {
    var onState: ((ARState) -> Void)? {
        get set
    }
    
    func setup(_ view: ARView)
    func place()
    func sendWave()
    func turn(_ deg: Float)
    func toggleMesh()
    func togglePoints()
    func toggleView()
    func clear()
}

@MainActor
protocol ARSessionServing {
    func start(_ view: ARView) -> Bool
    
    func showMesh(
        _ show: Bool,
        in view: ARView
    )
    
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
protocol ObjectMaking {
    func make() -> ObjectPart
}

@MainActor
protocol WaveSimulating {
    func run(
        in view: ARView,
        from start: WaveStart
    ) -> WaveData
}

@MainActor
protocol WaveDrawing {
    func make(
        from data: WaveData,
        showAllPoints: Bool
    ) -> Entity
}
