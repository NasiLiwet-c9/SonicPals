//
//  FPConeScan.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

import simd

struct FPConeScan {
    private let start: WaveStart
    private let range: Float
    
    private let hTan: Float
    private let vTan: Float
    
    // Enlarges only the hidden LiDAR scan area.
    private let scanScale: Float = 1.40
    
    init(data: WaveData) {
        start = data.start
        range = data.fpRange
        
        hTan = max(
            tan(
                data.setting.hAngleDeg
                * Float.pi
                / 180
            ) * scanScale,
            0.01
        )
        
        vTan = max(
            tan(
                data.setting.vAngleDeg
                * Float.pi
                / 180
            ) * scanScale,
            0.01
        )
    }
    
    func contains(
        _ point: SIMD3<Float>,
        pad: Float = 1.15
    ) -> Bool {
        let local = localPos(point)
        
        guard local.forward > 0.05,
              local.forward <= range + 0.55 else {
            return false
        }
        
        return amount(
            side: local.side,
            up: local.up,
            forward: local.forward
        ) <= pad
    }
    
    func sample(
        _ point: SIMD3<Float>
    ) -> (
        distanceM: Float,
        fade: Float
    )? {
        let local = localPos(point)
        
        guard local.forward > 0.05,
              local.forward <= range + 0.45 else {
            return nil
        }
        
        let coneAmount = amount(
            side: local.side,
            up: local.up,
            forward: local.forward
        )
        
        guard coneAmount <= 1.15 else {
            return nil
        }
        
        let distance = simd_distance(
            point,
            start.pos
        )
        
        let fade = smoothFade(
            value: coneAmount,
            fullUntil: 0.68,
            zeroAt: 1.15
        )
        
        return (
            distance,
            fade
        )
    }
    
    private func localPos(
        _ point: SIMD3<Float>
    ) -> (
        side: Float,
        up: Float,
        forward: Float
    ) {
        let delta = point - start.pos
        
        return (
            side: simd_dot(
                delta,
                start.right
            ),
            up: simd_dot(
                delta,
                start.up
            ),
            forward: simd_dot(
                delta,
                start.forward
            )
        )
    }
    
    private func amount(
        side: Float,
        up: Float,
        forward: Float
    ) -> Float {
        let width = max(
            forward * hTan,
            0.001
        )
        
        let height = max(
            forward * vTan,
            0.001
        )
        
        let x = side / width
        let y = up / height
        
        return sqrt(
            (x * x)
            + (y * y)
        )
    }
    
    private func smoothFade(
        value: Float,
        fullUntil: Float,
        zeroAt: Float
    ) -> Float {
        if value <= fullUntil {
            return 1
        }
        
        if value >= zeroAt {
            return 0
        }
        
        let step =
        (value - fullUntil)
        / (zeroAt - fullUntil)
        
        let smooth =
        step
        * step
        * (
            3
            - (2 * step)
        )
        
        return 1 - smooth
    }
}
