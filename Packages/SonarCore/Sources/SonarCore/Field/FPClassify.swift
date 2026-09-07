//
//  FPClassify.swift
//  SonarCore
//
//  Created by Shan Newcastle on 10/08/26.
//

public struct FPClassify: Sendable {
    public init() {}

    private let dangerMaxM: Float = 0.45
    private let warningMaxM: Float = 0.85
    private let semiSafeMaxM: Float = 1.20

    public func key(
        distanceM: Float,
        fade: Float
    ) -> FPKey {
        FPKey(
            band: band(distanceM),
            zone: zone(fade)
        )
    }

    private func band(
        _ distanceM: Float
    ) -> FPBand {
        if distanceM < dangerMaxM {
            return .hot
        }

        if distanceM < warningMaxM {
            return .near
        }

        if distanceM < semiSafeMaxM {
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
