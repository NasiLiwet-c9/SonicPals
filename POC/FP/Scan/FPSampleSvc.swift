//
//  FPSampleSvc.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
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
        let point = tri.center

        guard let coneSample =
            cone.sample(point)
        else {
            return nil
        }

        guard let hitFade =
            hit.fade(
                at: point,
                distanceM:
                    coneSample.distanceM
            )
        else {
            return nil
        }

        let fade =
            coneSample.fade
            * hitFade

        guard fade > 0.02 else {
            return nil
        }

        return FPSample(
            key:
                cls.key(
                    distanceM:
                        coneSample.distanceM,
                    fade: fade
                ),
            distanceM:
                coneSample.distanceM,
            fade: fade
        )
    }
}
