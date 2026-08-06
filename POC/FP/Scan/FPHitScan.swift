//
//  FPHitScan.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

import simd

struct FPHitScan {
    private struct Hit {
        let point: SIMD3<Float>
        let dir: SIMD3<Float>
        let distanceM: Float
    }
    
    private struct Match {
        let angle: Float
        let depth: Float
        let limit: Float
    }
    
    private let start: WaveStart
    private let hits: [Hit]
    private let mode: WaveMode
    
    init(data: WaveData) {
        start = data.start
        mode = data.setting.mode
        
        hits = data.hits.compactMap { hit in
            let delta =
            hit.point
            - data.start.pos
            
            let length = simd_length(delta)
            
            guard length > 0.001 else {
                return nil
            }
            
            return Hit(
                point: hit.point,
                dir: delta / length,
                distanceM: hit.distanceM
            )
        }
    }
    
    func fade(
        at point: SIMD3<Float>,
        distanceM: Float
    ) -> Float? {
        let delta = point - start.pos
        
        guard distanceM > 0.001 else {
            return nil
        }
        
        let direction = delta / distanceM
        
        let match =
        rayMatch(
            direction: direction,
            distanceM: distanceM
        )
        ?? nearbyMatch(
            point: point,
            distanceM: distanceM
        )
        
        guard let match else {
            return nil
        }
        
        let angleFade = smoothFade(
            value: match.angle,
            fullUntil: rayAngle * 0.24,
            zeroAt: rayAngle
        )
        
        let depthFade = max(
            1
            - (
                abs(match.depth)
                / max(match.limit, 0.001)
            ),
            0
        )
        
        return (
            0.42
            + (angleFade * 0.58)
        )
        * (
            0.68
            + (depthFade * 0.32)
        )
    }
    
    private func rayMatch(
        direction: SIMD3<Float>,
        distanceM: Float
    ) -> Match? {
        var best: Match?
        var bestScore =
        Float.greatestFiniteMagnitude
        
        for hit in hits {
            let dot = min(
                max(
                    simd_dot(
                        direction,
                        hit.dir
                    ),
                    -1
                ),
                1
            )
            
            let angle = acos(dot)
            
            guard angle <= rayAngle else {
                continue
            }
            
            let depth =
            distanceM
            - hit.distanceM
            
            // Larger front allowance reveals more of the same object.
            let frontLimit =
            0.60
            + (distanceM * 0.04)
            
            // Keep the rear allowance small so close objects still
            // hide surfaces farther behind them.
            let backLimit =
            0.16
            + (distanceM * 0.015)
            
            guard depth >= -frontLimit,
                  depth <= backLimit else {
                continue
            }
            
            let limit =
            depth < 0
            ? frontLimit
            : backLimit
            
            let angleScore =
            angle
            / max(rayAngle, 0.001)
            
            let depthScore =
            abs(depth)
            / max(limit, 0.001)
            
            let score =
            (angleScore * 0.65)
            + (depthScore * 0.35)
            
            if score < bestScore {
                bestScore = score
                
                best = Match(
                    angle: angle,
                    depth: depth,
                    limit: limit
                )
            }
        }
        
        return best
    }
    
    private func nearbyMatch(
        point: SIMD3<Float>,
        distanceM: Float
    ) -> Match? {
        guard let hit = hits.min(
            by: {
                simd_distance_squared(
                    $0.point,
                    point
                )
                < simd_distance_squared(
                    $1.point,
                    point
                )
            }
        ) else {
            return nil
        }
        
        let worldDistance = simd_distance(
            hit.point,
            point
        )
        
        // Expands the LiDAR reveal around every real ray hit.
        let radius =
        0.60
        + min(
            distanceM * 0.10,
            0.35
        )
        
        guard worldDistance <= radius else {
            return nil
        }
        
        let depth =
        distanceM
        - hit.distanceM
        
        let frontLimit: Float = 0.68
        
        // Remains small to prevent the wall behind
        // a closer object from being revealed.
        let backLimit: Float = 0.15
        
        guard depth >= -frontLimit,
              depth <= backLimit else {
            return nil
        }
        
        return Match(
            angle: rayAngle * 0.70,
            depth: depth,
            limit:
                depth < 0
            ? frontLimit
            : backLimit
        )
    }
    
    private var rayAngle: Float {
        let degrees: Float
        
        switch mode {
        case .far:
            degrees = 15
            
        case .near:
            degrees = 18
            
        case .close:
            degrees = 21
        }
        
        return degrees
        * Float.pi
        / 180
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
