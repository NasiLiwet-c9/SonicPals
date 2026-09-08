//
//  RealityShade.swift
//  POC
//
//  Created by Shan Newcastle on 19/08/26.
//

import CoreGraphics
import RealityKit
import UIKit
import simd

@MainActor
enum RealityShade {
    private static let group = ModelSortGroup()
    private static let darkName = "missionShadeDark"
    private static let lightName = "missionShadeLight"

    static func makeAnchor() -> AnchorEntity {
        let anchor = AnchorEntity(.camera)
        anchor.name = "missionShade"
        anchor.isEnabled = false
        return anchor
    }

    static func prepare(_ anchor: AnchorEntity) async {
        guard anchor.findEntity(named: darkName) == nil else { return }

        let dark = await makePlane(
            name: darkName,
            center: UICfg.Shade.darkMid,
            middle: UICfg.Shade.darkHalf,
            edge: UICfg.Shade.darkEdge
        )

        let light = await makePlane(
            name: lightName,
            center: UICfg.Shade.liteMid,
            middle: UICfg.Shade.liteHalf,
            edge: UICfg.Shade.liteEdge
        )

        dark.isEnabled = false
        light.isEnabled = false

        anchor.addChild(dark)
        anchor.addChild(light)
    }

    static func update(
        _ anchor: AnchorEntity,
        visible: Bool,
        dim: Bool
    ) {
        anchor.isEnabled = visible
        guard visible else { return }

        anchor.findEntity(named: darkName)?.isEnabled = dim
        anchor.findEntity(named: lightName)?.isEnabled = !dim
    }

    static func keepBright(
        _ entity: Entity,
        order: Int32 = 1
    ) {
        if entity.components.has(ModelComponent.self) {
            entity.components.set(
                ModelSortGroupComponent(group: group, order: order)
            )
        }

        for child in entity.children {
            keepBright(child, order: order)
        }
    }

    private static func makePlane(
        name: String,
        center: CGFloat,
        middle: CGFloat,
        edge: CGFloat
    ) async -> ModelEntity {
        let mesh = MeshResource.generatePlane(width: 1.2, depth: 2.2)

        let material = await makeMaterial(
            name: name,
            center: center,
            middle: middle,
            edge: edge
        )

        let plane = ModelEntity(
            mesh: mesh,
            materials: [material]
        )

        plane.name = name
        plane.position = SIMD3<Float>(0, 0, -0.12)

        plane.orientation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))

        plane.components.set(
            ModelSortGroupComponent(group: group, order: 0)
        )

        return plane
    }

    private static func makeMaterial(
        name: String,
        center: CGFloat,
        middle: CGFloat,
        edge: CGFloat
    ) async -> UnlitMaterial {
        var material: UnlitMaterial

        if let image = gradientImage(
            center: center,
            middle: middle,
            edge: edge
        ),
        let texture = try? await TextureResource(
            image: image,
            withName: name,
            options: .init(semantic: .color)
        ) {
            material = UnlitMaterial(texture: texture)
        } else {
            material = UnlitMaterial(color: UIColor.black.withAlphaComponent(middle))
        }

        material.faceCulling = .none
        material.readsDepth = false
        material.writesDepth = false

        material.blending = .transparent(opacity: .init(floatLiteral: 1))

        return material
    }

    private static func gradientImage(
        center: CGFloat,
        middle: CGFloat,
        edge: CGFloat
    ) -> CGImage? {
        let size = CGSize(width: 256, height: 256)

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false

        let image = UIGraphicsImageRenderer(
            size: size,
            format: format
        ).image { context in
            let colors = [
                UIColor.black.withAlphaComponent(center).cgColor,
                UIColor.black.withAlphaComponent(middle).cgColor,
                UIColor.black.withAlphaComponent(edge).cgColor
            ] as CFArray

            let locations: [CGFloat] = [0, 0.58, 1]
            let space = CGColorSpaceCreateDeviceRGB()

            guard let gradient = CGGradient(
                colorsSpace: space,
                colors: colors,
                locations: locations
            ) else {
                return }

            let point = CGPoint(x: size.width * 0.5, y: size.height * 0.5)

            let radius = hypot(
                size.width,
                size.height
            ) * 0.5

            context.cgContext.drawRadialGradient(
                gradient,
                startCenter: point,
                startRadius: 0,
                endCenter: point,
                endRadius: radius,
                options: [.drawsAfterEndLocation]
            )
        }

        return image.cgImage
    }
}
