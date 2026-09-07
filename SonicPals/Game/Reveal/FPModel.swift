//
//  FPModel.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import RealityKit
import SonarCore

/// One band/zone bucket of a ping as real geometry. The bucketing itself
/// is pure and lives in `SonarCore`, this holds `Entity`, so it cannot
struct FPMeshLayer {
    let root: Entity
    let pulse: Entity
    let trace: Entity

    let delayMs: Int64
    let zone: FPZone
}
