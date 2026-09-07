//
//  FPSampleSvc.swift
//  SonarCore
//
//  Created by Shan Newcastle on 10/08/26.
//

public struct FPSampleSvc: Sendable {
    private let cone: FPConeScan
    private let hit: FPHitScan
    private let cls: FPClassify

    public init(
        cone: FPConeScan,
        hit: FPHitScan,
        cls: FPClassify
    ) {
        self.cone = cone
        self.hit = hit
        self.cls = cls
    }

    public func make(
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
