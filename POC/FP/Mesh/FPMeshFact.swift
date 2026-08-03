//
//  FPMeshFact.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

import RealityKit
import UIKit

@MainActor
final class FPMeshFact:
    FPMeshMakePort {
    
    private let coneMs: Float = 900
    
    func make(
        from data: FPMeshData,
        key: FPKey,
        range: Float
    ) -> FPMeshLayer? {
        guard !data.pos.isEmpty,
              !data.idx.isEmpty,
              let minM = data.minM else {
            return nil
        }
        
        var desc = MeshDescriptor(
            name:
                "fpMesh"
            + "\(key.band.rawValue)"
            + "\(key.zone.rawValue)"
        )
        
        desc.positions = .init(
            data.pos
        )
        
        desc.primitives = .triangles(
            data.idx
        )
        
        guard let mesh = try? MeshResource.generate(
            from: [desc]
        ) else {
            return nil
        }
        
        let style = key.style
        let root = Entity()
        
        root.name =
        "fpLayer"
        + "\(key.band.rawValue)"
        + "\(key.zone.rawValue)"
        
        root.isEnabled = false
        
        let glow = ModelEntity(
            mesh: mesh,
            materials: [
                makeMat(
                    color: style.color,
                    alpha: style.glowA,
                    lines: false
                )
            ]
        )
        
        let fill = ModelEntity(
            mesh: mesh,
            materials: [
                makeMat(
                    color: style.color,
                    alpha: style.fillA,
                    lines: false
                )
            ]
        )
        
        let wire = ModelEntity(
            mesh: mesh,
            materials: [
                makeMat(
                    color: style.color,
                    alpha: style.wireA,
                    lines: true
                )
            ]
        )
        
        glow.name = "glow"
        fill.name = "fill"
        wire.name = "wire"
        
        root.addChild(glow)
        root.addChild(fill)
        root.addChild(wire)
        
        let amount = min(
            max(
                minM
                / max(range, 0.1),
                0.03
            ),
            1
        )
        
        let travelMs = Int64(
            (
                amount
                * coneMs
            )
            .rounded()
        )
        
        return FPMeshLayer(
            root: root,
            delayMs:
                travelMs
            + style.delayMs,
            zone: key.zone
        )
    }
    
    private func makeMat(
        color: UIColor,
        alpha: Float,
        lines: Bool
    ) -> UnlitMaterial {
        var mat = UnlitMaterial(
            color: color
        )
        
        mat.triangleFillMode =
        lines
        ? .lines
        : .fill
        
        mat.faceCulling = .none
        
        // The scan filter handles near/far blocking.
        // This prevents the real mesh from hiding its own overlay.
        mat.readsDepth = false
        mat.writesDepth = false
        
        mat.blending = .transparent(
            opacity: .init(
                floatLiteral: min(
                    max(alpha, 0),
                    1
                )
            )
        )
        
        return mat
    }
}
