//
//  WaveDraw.swift
//  POC
//
//  Created by Shanon Newcastle on 03/08/26.
//

import RealityKit
import UIKit
import simd

@MainActor
final class WaveDraw: WaveDrawing {
    private let shape: WaveShape
    private let ringCount = 3
    private let ringParts = 16
    private let maxViewDistance: Float = 1.35
    
    init(shape: WaveShape) {
        self.shape = shape
    }
    
    func make(
        from data: WaveData,
        showAllPoints: Bool
    ) -> Entity {
        let root = Entity()
        root.name = "wave"
        
        addRings(
            to: root,
            data: data
        )
        
        addMainResult(
            to: root,
            data: data
        )
        
        if showAllPoints {
            addPoints(
                to: root,
                data: data
            )
        }
        
        return root
    }
    
    private func addRings(
        to root: Entity,
        data: WaveData
    ) {
        let distance = min(
            data.viewDistance,
            maxViewDistance
        )
        
        let hScale = tan(
            toRad(data.setting.hAngleDeg)
        )
        
        let vScale = tan(
            toRad(data.setting.vAngleDeg)
        )
        
        for index in 1...ringCount {
            let step = Float(index) / Float(ringCount)
            let ringDistance = distance * step
            
            let center =
            data.start.pos
            + (data.start.forward * ringDistance)
            
            root.addChild(
                shape.ring(
                    center: center,
                    right: data.start.right,
                    up: data.start.up,
                    radiusX: min(
                        hScale * ringDistance,
                        0.28
                    ),
                    radiusY: min(
                        vScale * ringDistance,
                        0.20
                    ),
                    parts: ringParts,
                    lineRadius: 0.002,
                    color: .systemCyan,
                    alpha: 0.7 - (step * 0.22)
                )
            )
        }
    }
    
    private func addMainResult(
        to root: Entity,
        data: WaveData
    ) {
        if let echo = data.strongestEcho {
            addEcho(
                to: root,
                data: data,
                hit: echo
            )
            return
        }
        
        if let miss =
            data.strongestMiss
            ?? data.nearestHit {
            addMiss(
                to: root,
                data: data,
                hit: miss
            )
        }
    }
    
    private func addEcho(
        to root: Entity,
        data: WaveData,
        hit: WaveHit
    ) {
        let point = wallPoint(
            hit,
            gap: 0.014
        )
        
        root.addChild(
            shape.line(
                from: data.start.pos,
                to: point,
                radius:
                    0.0035
                + (hit.power * 0.0015),
                color: .systemGreen,
                alpha: 1
            )
        )
        
        root.addChild(
            shape.dot(
                at: point,
                radius:
                    0.015
                + (hit.power * 0.004),
                color: .systemGreen,
                alpha: 1
            )
        )
        
        root.addChild(
            shape.dot(
                at: point,
                radius: 0.005,
                color: .white,
                alpha: 1
            )
        )
    }
    
    private func addMiss(
        to root: Entity,
        data: WaveData,
        hit: WaveHit
    ) {
        let point = wallPoint(
            hit,
            gap: 0.014
        )
        
        let axes = wallAxes(
            normal: hit.normal
        )
        
        root.addChild(
            shape.flow(
                from: data.start.pos,
                to: point,
                count: 7,
                radius: 0.004,
                color: .systemRed
            )
        )
        
        root.addChild(
            shape.cross(
                at: point,
                right: axes.right,
                up: axes.up,
                size: 0.03,
                lineRadius: 0.004,
                color: .systemRed
            )
        )
        
        guard hit.anglePower < 0.65 else {
            return
        }
        
        let end =
        point
        + (hit.bounceDir * 0.24)
        
        root.addChild(
            shape.flow(
                from: point,
                to: end,
                count: 4,
                radius: 0.0035,
                color: .systemRed
            )
        )
    }
    
    private func addPoints(
        to root: Entity,
        data: WaveData
    ) {
        for hit in data.hits {
            let point = wallPoint(
                hit,
                gap: 0.01
            )
            
            if hit.heard {
                root.addChild(
                    shape.dot(
                        at: point,
                        radius:
                            0.008
                        + (hit.power * 0.002),
                        color: .systemGreen,
                        alpha: 1
                    )
                )
            } else {
                let axes = wallAxes(
                    normal: hit.normal
                )
                
                root.addChild(
                    shape.cross(
                        at: point,
                        right: axes.right,
                        up: axes.up,
                        size: 0.012,
                        lineRadius: 0.0022,
                        color: .systemRed
                    )
                )
            }
        }
    }
    
    private func wallPoint(
        _ hit: WaveHit,
        gap: Float
    ) -> SIMD3<Float> {
        hit.point
        + (safeNormal(hit.normal) * gap)
    }
    
    private func wallAxes(
        normal: SIMD3<Float>
    ) -> (
        right: SIMD3<Float>,
        up: SIMD3<Float>
    ) {
        let normal = safeNormal(normal)
        
        let ref = abs(normal.y) < 0.9
        ? SIMD3<Float>(0, 1, 0)
        : SIMD3<Float>(1, 0, 0)
        
        let right = simd_normalize(
            simd_cross(ref, normal)
        )
        
        let up = simd_normalize(
            simd_cross(normal, right)
        )
        
        return (right, up)
    }
    
    private func safeNormal(
        _ normal: SIMD3<Float>
    ) -> SIMD3<Float> {
        let length = simd_length(normal)
        
        guard length > 0.001 else {
            return SIMD3<Float>(0, 1, 0)
        }
        
        return normal / length
    }
    
    private func toRad(
        _ degrees: Float
    ) -> Float {
        degrees * Float.pi / 180
    }
}
