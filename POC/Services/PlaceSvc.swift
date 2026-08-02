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
        let planes = view.raycast(
            from: point,
            allowing: .existingPlaneGeometry,
            alignment: .horizontal
        )

        if let first = planes.first {
            return first
        }

        let estimates = view.raycast(
            from: point,
            allowing: .estimatedPlane,
            alignment: .horizontal
        )

        return estimates.first
    }
}
