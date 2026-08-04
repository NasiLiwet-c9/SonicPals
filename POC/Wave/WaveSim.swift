//
//  WaveSim.swift
//  POC
//
<<<<<<< HEAD
//  Created by Shanon Giuly Istanto on 03/08/26.
//  Updated by Asaryun on 03/08/26.
=======
//  Created by Shanon Newcastle on 03/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//
>>>>>>> shan_POC

import RealityKit
import simd

@MainActor
final class WaveSim:
    WaveSimulating {
    
    private let set:
    WaveSet
    
    private let rayMaker:
    RayMaker
    
    private let echoCalc:
    EchoCalc
    
    private let maxDistance:
    Float
    
    private let soundSpeed:
    Float
    
    init(
        set: WaveSet? = nil,
        rayMaker: RayMaker? = nil,
        echoCalc: EchoCalc? = nil,
        maxDistance: Float = 5,
        soundSpeed: Float = 343
    ) {
        self.set = set ?? .standard
        self.rayMaker = rayMaker ?? RayMaker()
        self.echoCalc = echoCalc ?? EchoCalc()
        self.maxDistance = maxDistance
        self.soundSpeed = soundSpeed
    }
    
    func run(
        in view: ARView,
        from start: WaveStart
    ) -> WaveData {
        let checkRays = rayMaker.make(
            for: set.check,
            ringCount: 2
        )
        
        let nearest = nearestDistance(
            in: view,
            from: start,
            rays: checkRays
        )
        
        let setting = set.pick(
            nearest
        )
        
        let rays = rayMaker.make(
            for: setting
        )
        
        let hits = scan(
            in: view,
            from: start,
            setting: setting,
            rays: rays
        )
        
        return WaveData(
            start: start,
            setting: setting,
            hits: hits,
            rayCount: rays.count,
            maxDistance: maxDistance,
            soundSpeed: soundSpeed
        )
    }
    
    private func nearestDistance(
        in view: ARView,
        from start: WaveStart,
        rays: [WaveRay]
    ) -> Float? {
        var nearest: Float?
        
        for ray in rays {
            let direction = worldDir(
                ray.dir,
                from: start
            )
            
            guard let hit = firstHit(
                in: view,
                start: start.pos,
                direction: direction
            ) else {
                continue
            }
            
            nearest = min(
                nearest ?? hit.distance,
                hit.distance
            )
        }
        
        return nearest
    }
    
    private func scan(
        in view: ARView,
        from start: WaveStart,
        setting: WaveSetting,
        rays: [WaveRay]
    ) -> [WaveHit] {
        var hits: [WaveHit] = []
        
        hits.reserveCapacity(
            rays.count
        )
        
        for ray in rays {
            let direction = worldDir(
                ray.dir,
                from: start
            )
            
            guard let hit = firstHit(
                in: view,
                start: start.pos,
                direction: direction
            ) else {
                continue
            }
            
            var normal = simd_normalize(
                hit.normal
            )
            
            if simd_dot(
                direction,
                normal
            ) > 0 {
                normal = -normal
            }
            
            let anglePower = max(
                simd_dot(
                    -direction,
                     normal
                ),
                0.05
            )
            
            let levelDb = echoCalc.level(
                distanceM: hit.distance,
                rayPower: ray.power,
                anglePower: anglePower,
                frequencyKHz:
                    setting.midKHz
            )
            
            let heard = echoCalc.heard(
                levelDb: levelDb,
                distanceM: hit.distance,
                setting: setting,
                soundSpeed: soundSpeed
            )
            
            let bounceDir = simd_normalize(
                direction
                - (
                    2
                    * simd_dot(
                        direction,
                        normal
                    )
                    * normal
                )
            )
            
            hits.append(
                WaveHit(
                    point: hit.position,
                    normal: normal,
                    bounceDir: bounceDir,
                    distanceM: hit.distance,
                    levelDb: levelDb,
                    power: echoCalc.power(
                        levelDb: levelDb
                    ),
                    sideDeg: ray.sideDeg,
                    anglePower: anglePower,
                    heard: heard
                )
            )
        }
        
        return hits
    }
    
    private func firstHit(
        in view: ARView,
        start: SIMD3<Float>,
        direction: SIMD3<Float>
    ) -> CollisionCastHit? {
        view.scene.raycast(
            origin: start,
            direction: direction,
            length: maxDistance,
            query: .nearest,
            mask: .sceneUnderstanding,
            relativeTo: nil
        )
        .first
    }
    
    private func worldDir(
        _ direction: SIMD3<Float>,
        from start: WaveStart
    ) -> SIMD3<Float> {
        simd_normalize(
            (start.right * direction.x)
            + (start.up * direction.y)
            + (start.forward * direction.z)
        )
    }
}
