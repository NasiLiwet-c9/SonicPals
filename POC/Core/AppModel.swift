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

    enum HUDStage {
        case scanning
        case scanCompletePrompt
        case transitioning
        case mission
    }

    var hudStage: HUDStage = .scanning
    var scanReady = false
    var scanProgress: Float = 0
    var scanTurn: FPScanTurn = .none

    var missionStarted = false
    var missionComplete = false
    var missionDark = false
    var missionDialogue = ""
    var missionDialogueID = 0
    var missionDialogueVisible = false

    let missionMangoTarget = 3
}
