//
//  WaveSim.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import RealityKit
import simd

@MainActor
protocol WaveSimulating {
    func run(
        in scene: Scene,
        from start: WaveStart
    ) -> WaveData
}

@MainActor
final class WaveSim: WaveSimulating {
    private let set: WaveSet
    private let rayMaker: RayMaker
    private let echoCalc: EchoCalc
    
    private let maxDistance: Float
    private let soundSpeed: Float
    
    init(
        set: WaveSet? = nil,
        rayMaker: RayMaker? = nil,
        echoCalc: EchoCalc? = nil,
        maxDistance: Float = 1.5,
        soundSpeed: Float = 343
    ) {
        self.set = set ?? .standard
        self.rayMaker = rayMaker ?? RayMaker()
        self.echoCalc = echoCalc ?? EchoCalc()
        self.maxDistance = maxDistance
        self.soundSpeed = soundSpeed
    }
    
    func run(
        in scene: Scene,
        from start: WaveStart
    ) -> WaveData {
        let checkRays = rayMaker.make(
            for: set.check,
            ringCount: 2
        )
        
        let nearest = nearestDistance(
            in: scene,
            from: start,
            rays: checkRays
        )
        
        let setting = set.pick(nearest)
        let rays = rayMaker.make(for: setting)
        
        let hits = scan(
            in: scene,
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
        in scene: Scene,
        from start: WaveStart,
        rays: [WaveRay]
    ) -> Float? {
        var nearest: Float?
        
        for ray in rays {
            let dir = worldDir(
                ray.dir,
                from: start
            )
            
            guard let hit = firstHit(
                in: scene,
                start: start.pos,
                direction: dir
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
        in scene: Scene,
        from start: WaveStart,
        setting: WaveSetting,
        rays: [WaveRay]
    ) -> [WaveHit] {
        var hits: [WaveHit] = []
        hits.reserveCapacity(rays.count)
        
        for ray in rays {
            let dir = worldDir(
                ray.dir,
                from: start
            )
            
            guard let hit = firstHit(
                in: scene,
                start: start.pos,
                direction: dir
            ) else {
                continue
            }
            
            var normal = simd_normalize(hit.normal)
            
            if simd_dot(dir, normal) > 0 {
                normal = -normal
            }
            
            let anglePower = max(
                simd_dot(-dir, normal),
                0.05
            )
            
            let levelDb = echoCalc.level(
                distanceM: hit.distance,
                rayPower: ray.power,
                anglePower: anglePower,
                frequencyKHz: setting.midKHz
            )
            
            let heard = echoCalc.heard(
                levelDb: levelDb,
                distanceM: hit.distance,
                setting: setting,
                soundSpeed: soundSpeed
            )
            
            let bounceDir = simd_normalize(
                dir - (
                    2
                    * simd_dot(dir, normal)
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
                    power: echoCalc.power(levelDb: levelDb),
                    sideDeg: ray.sideDeg,
                    anglePower: anglePower,
                    heard: heard
                )
            )
        }
        
        return hits
    }
    
    private func firstHit(
        in scene: Scene,
        start: SIMD3<Float>,
        direction: SIMD3<Float>
    ) -> CollisionCastHit? {
        scene.raycast(
            origin: start,
            direction: direction,
            length: maxDistance,
            query: .nearest,
            mask: .sceneUnderstanding,
            relativeTo: nil
        ).first
    }
    
    private func worldDir(
        _ dir: SIMD3<Float>,
        from start: WaveStart
    ) -> SIMD3<Float> {
        simd_normalize(
            (start.right * dir.x)
            + (start.up * dir.y)
            + (start.forward * dir.z)
        )
    }
}
