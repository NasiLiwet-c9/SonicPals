//
//  GuideArrow.swift
//  POC
//
//  Created by Shan Newcastle on 04/09/26.
//

import RealityKit
import UIKit
import simd

struct GuideComp: Component {}

/// Rides the camera anchor, so it stays on screen even with the tree
/// behind the player. A tilted dial: the arrow rolls to the bearing
@MainActor
enum GuideArrow {
    private static let name = "treeGuideArrow"

    /// Toggled here, not on the `GuideComp` node: `performQuery` skips
    /// disabled entities
    static let bodyName = "treeGuideArrowBody"

    /// Applied in the anchor's frame, outside the roll. Steeper than
    /// this and pointing away foreshortens into a mushroom
    static let dialPitch = simd_quatf(
        angle: -0.60,
        axis: SIMD3<Float>(1, 0, 0)
    )

    /// Between the reticle and the bubble. Mesh sizes assume 42cm
    private static let seat = SIMD3<Float>(0, -0.055, -0.42)

    /// How far the plate is squashed along its normal
    private static let plateFlatten: Float = 0.24

    private static let violet = UIColor(
        red: 0.62,
        green: 0.52,
        blue: 1,
        alpha: 1
    )

    static func makeAnchor() -> AnchorEntity {
        let anchor = AnchorEntity(.camera)
        anchor.name = "treeGuide"

        let arrow = Entity()
        arrow.name = name
        arrow.position = seat
        arrow.components.set(GuideComp())

        let body = makeArrow()
        body.name = bodyName
        body.isEnabled = false

        arrow.addChild(body)
        anchor.addChild(arrow)

        return anchor
    }

    // MARK: - Mesh

    /// Points along +Y, so aiming is a single roll about the view axis
    private static func makeArrow() -> Entity {
        let root = Entity()

        let head = ModelEntity(
            mesh: .generateCone(height: 0.030, radius: 0.019),
            materials: [material(bright: true)]
        )

        head.position = SIMD3<Float>(0, 0.016, 0)

        let shaft = ModelEntity(
            mesh: .generateBox(
                size: SIMD3<Float>(0.0135, 0.038, 0.011),
                cornerRadius: 0.004
            ),
            materials: [material(bright: false)]
        )

        shaft.position = SIMD3<Float>(0, -0.022, 0)

        root.addChild(head)
        root.addChild(shaft)
        root.addChild(makeLight())

        return root
    }

    /// Its own light, so any room looks the same. Short radius keeps it
    /// off the reveal mesh
    private static func makeLight() -> Entity {
        let entity = Entity()

        entity.components.set(
            PointLightComponent(
                color: .white,
                intensity: 520,
                attenuationRadius: 0.35
            )
        )

        // Raking, a frontal light flattens the cone
        entity.position = SIMD3<Float>(0.13, 0.05, 0.07)

        return entity
    }

    /// Emissive enough to survive the shade, dim enough to still shade
    private static func material(bright: Bool) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()

        let tint = bright
            ? violet
            : violet.darker(by: 0.26)

        material.baseColor = .init(tint: tint)
        material.emissiveColor = .init(color: tint)
        material.emissiveIntensity = bright ? 0.34 : 0.20
        material.roughness = .init(floatLiteral: 0.32)
        material.metallic = .init(floatLiteral: 0)

        material.blending = .transparent(
            opacity: .init(floatLiteral: 0.7)
        )

        return material
    }
}

private extension UIColor {
    func darker(by amount: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        guard getHue(
            &hue,
            saturation: &saturation,
            brightness: &brightness,
            alpha: &alpha
        ) else {
            return self
        }

        return UIColor(
            hue: hue,
            saturation: saturation,
            brightness: max(brightness - amount, 0),
            alpha: alpha
        )
    }
}
