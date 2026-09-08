//
//  FPMeshBuild.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import ARKit
import RealityKit
import SonarCore

@MainActor
final class FPMeshBuild: FPMeshBuilding {
    private let read: any FPMeshReadPort
    private let pack: any FPMeshPackPort
    private let fact: any FPMeshMakePort

    private let maxRead = 16_000

    init(
        read: any FPMeshReadPort,
        pack: any FPMeshPackPort,
        fact: any FPMeshMakePort
    ) {
        self.read = read
        self.pack = pack
        self.fact = fact
    }
    
    func make(
        session: ARSession,
        from data: WaveData
    ) -> [FPMeshLayer] {
        let cone = FPConeScan(data: data)
        let hit = FPHitScan(data: data)
        
        let sample = FPSampleSvc(
            cone: cone,
            hit: hit,
            cls: FPClassify()
        )
        
        let tris = read.read(
            session: session,
            cone: cone,
            limit: maxRead
        )
        
        var items: [FPItem] = []
        items.reserveCapacity(tris.count)
        
        for tri in tris {
            guard let result = sample.make(tri) else {
                continue
            }
            
            items.append(
                FPItem(
                    tri: tri,
                    sample: result
                )
            )
        }
        
        let buckets = pack.make(
            from: items,
            camera: data.start.pos
        )
        
        return buckets
            .compactMap { key, meshData in
                fact.make(
                    from: meshData,
                    key: key,
                    range: data.fpRange
                )
            }
            .sorted {
                $0.delayMs < $1.delayMs
            }
    }
}
