//
//  PlaceSvc.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//

import ARKit
import RealityKit
import UIKit

@MainActor
final class PlaceSvc:
    PlaceServing {
    
    func hit(
        in view: ARView,
        at point: CGPoint
    ) -> ARRaycastResult? {
        let planes =
        view.raycast(
            from: point,
            allowing:
                    .existingPlaneGeometry,
            alignment:
                    .horizontal
        )
        
        if let first =
            planes.first {
            return first
        }
        
        return view.raycast(
            from: point,
            allowing:
                    .estimatedPlane,
            alignment:
                    .horizontal
        )
        .first
    }
}
