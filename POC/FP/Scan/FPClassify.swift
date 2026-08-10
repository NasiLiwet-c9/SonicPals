//
//  FPClassify.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

struct FPClassify {
    func key(
        distanceM: Float,
        fade: Float
    ) -> FPKey {
        FPKey(
            band:
                band(distanceM),
            zone:
                zone(fade)
        )
    }

    private func band(
        _ distanceM: Float
    ) -> FPBand {
        if distanceM < 0.45 {
            return .hot
        }

        if distanceM < 0.85 {
            return .near
        }

        if distanceM < 1.20 {
            return .mid
        }

        return .far
    }

    private func zone(
        _ fade: Float
    ) -> FPZone {
        if fade >= 0.66 {
            return .core
        }

        if fade >= 0.26 {
            return .soft
        }

        return .edge
    }
}
