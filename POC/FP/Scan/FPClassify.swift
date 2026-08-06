//
//  FPClassify.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

struct FPClassify {
    func key(
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
        // Red is reserved for very close surfaces.
        if distanceM < 0.40 {
            return .hot
        }
        
        if distanceM < 1.40 {
            return .near
        }
        
        if distanceM < 3 {
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
