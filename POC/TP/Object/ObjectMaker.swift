//
//  ObjectMaker.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

import RealityKit
import simd

@MainActor
final class ObjectMaker:
    ObjectMaking {
    
    private let asset: TPAssetSvc
    
    var loadError: String? {
        asset.loadError
    }
    
    init(
        asset: TPAssetSvc
    ) {
        self.asset = asset
    }
    
    func prepare() async -> Bool {
        await asset.prepare()
    }
    
    func make() -> ObjectPart? {
        guard let body = asset.makeBody() else {
            return nil
        }
        
        let root = Entity()
        root.name = "object"
        
        root.addChild(
            body.entity
        )
        
        // Invisible origin for the third-person ultrasonic wave.
        let waveStart = Entity()
        waveStart.name = "waveStart"
        
        waveStart.position = SIMD3<Float>(
            0,
            0,
            -(body.size.z * 0.52) - 0.03
        )
        
        root.addChild(
            waveStart
        )
        
        return ObjectPart(
            root: root,
            waveStart: waveStart
        )
    }
}
