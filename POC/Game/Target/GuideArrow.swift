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

/// A 3D arrow pointing at the tree, riding the camera anchor so it stays
/// on screen even when the tree is behind the player.
///
/// Faces the camera and rolls to the bearing: a cone pointing away from
/// the viewer would just render as a circle.
@MainActor
enum GuideArrow {
    private static let name = "treeGuideArrow"

    /// Visibility is toggled here, not on the `GuideComp` node:
    /// `performQuery` skips disabled entities, so hiding that node would
    /// leave the system unable to find it again.
    static let bodyName = "treeGuideArrowBody"

    /// Must be applied in the arrow's own frame (`roll * lean`). In the
    /// anchor's frame it skews the apparent direction when the arrow
    /// points up or down.
    static let lean = simd_quatf(
        angle: -0.40,
        axis: SIMD3<Float>(1, 0, 0)
    )

    /// Sits between the reticle and the dialogue bubble, which used to
    /// cover it. Mesh sizes are tuned against this 42cm distance.
    private static let seat = SIMD3<Float>(0, -0.055, -0.42)

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

    /// Points along +Y, so aiming is a single roll about the view axis.
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

        shaft.position = SIMD3<Float>(0, -0.018, 0)

        root.addChild(head)
        root.addChild(shaft)
        root.addChild(makeLight())

        return root
    }

    /// Its own light, so it looks the same in any room. The short
    /// attenuation radius keeps it off the reveal mesh.
    private static func makeLight() -> Entity {
        let entity = Entity()

        entity.components.set(
            PointLightComponent(
                color: .white,
                intensity: 520,
                attenuationRadius: 0.35
            )
        )

        // Raking: a frontal light flattens the cone into a triangle.
        entity.position = SIMD3<Float>(0.13, 0.05, 0.07)

        return entity
    }

    /// Lightly emissive to survive the mission shade, but dim enough
    /// that the light still shades it — full emissive blows it flat.
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
            opacity: .init(floatLiteral: 0.8)
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
