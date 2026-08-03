//
//  FPConeDraw.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

import RealityKit
import simd

@MainActor
final class FPConeDraw: FPConeDrawing {
    private let shape: FPConeShape
    private let count = 3
    private let gapMs: Int64 = 180
    private let duration = 0.9
    
    init(shape: FPConeShape) {
        self.shape = shape
    }
    
    func make(from data: WaveData) -> Entity {
        let root = Entity()
        root.name = "fpCones"
        
        let frame = Entity()
        frame.position = data.start.pos
        
        let basis = simd_float3x3(
            columns: (
                data.start.right,
                data.start.up,
                -data.start.forward
            )
        )
        
        frame.orientation = simd_quatf(basis)
        root.addChild(frame)
        
        let length = data.fpRange
        
        // Equal X and Y radius makes the visible ring circular.
        // The smaller angle prevents the cone from becoming larger.
        let angle = min(
            data.setting.hAngleDeg,
            data.setting.vAngleDeg
        )
        
        let radius = min(
            tan(toRad(angle)) * length,
            1
        )
        
        for index in 0..<count {
            let cone = shape.make(
                length: length,
                radiusX: radius,
                radiusY: radius
            )
            
            cone.name = "fpCone\(index)"
            cone.scale = SIMD3<Float>(
                repeating: 0.012
            )
            
            cone.isEnabled = false
            
            frame.addChild(cone)
            
            animate(
                cone,
                delayMs: Int64(index) * gapMs
            )
        }
        
        return root
    }
    
    private func animate(
        _ cone: Entity,
        delayMs: Int64
    ) {
        Task { @MainActor [weak cone] in
            try? await Task.sleep(
                for: .milliseconds(delayMs)
            )
            
            guard let cone,
                  let parent = cone.parent else {
                return
            }
            
            cone.isEnabled = true
            
            var target = cone.transform
            
            target.scale = SIMD3<Float>(
                repeating: 1
            )
            
            cone.move(
                to: target,
                relativeTo: parent,
                duration: duration,
                timingFunction: .easeOut
            )
            
            try? await Task.sleep(
                for: .milliseconds(1_100)
            )
            
            cone.removeFromParent()
        }
    }
    
    private func toRad(
        _ degrees: Float
    ) -> Float {
        degrees * Float.pi / 180
    }
}
