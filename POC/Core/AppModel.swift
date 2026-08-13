//
//  AppModel.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import Observation

@MainActor
@Observable
final class AppModel {
    var msg = ""
    var lidarOK = false
    var hasTarget = false
    var targetFound = false
    var dimOn = true
    var waveSeq = 0

    var mangoEatReady = false
    var mangoEatenCount = 0

    var canWave: Bool {
        lidarOK
    }

    var canSpawn: Bool {
        lidarOK
    }
}
