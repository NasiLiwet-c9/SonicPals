//
//  FPSampleSvc.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//

struct FPSampleSvc {
    private let cone: FPConeScan
    private let hit: FPHitScan
    private let cls: FPClassify
    
    init(
        cone: FPConeScan,
        hit: FPHitScan,
        cls: FPClassify
    ) {
        self.cone = cone
        self.hit = hit
        self.cls = cls
    }
    
    func make(
        _ tri: FPTri
    ) -> FPSample? {
        var best: FPSample?
        
        for point in tri.points {
            guard let coneResult =
                    cone.sample(point),
                  let hitFade =
                    hit.fade(
                        at: point,
                        distanceM:
                            coneResult.distanceM
                    ) else {
                continue
            }
            
            let fade =
            coneResult.fade
            * hitFade
            
            guard fade > 0.025 else {
                continue
            }
            
            let sample = FPSample(
                key: cls.key(
                    distanceM:
                        coneResult.distanceM,
                    fade: fade
                ),
                distanceM:
                    coneResult.distanceM,
                fade: fade
            )
            
            if best == nil
                || sample.fade > best!.fade {
                best = sample
            }
        }
        
        return best
    }
}
