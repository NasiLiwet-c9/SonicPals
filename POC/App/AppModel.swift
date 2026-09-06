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

    /// First-run coaching, shown over the live camera. Driven by `CoachSvc`.
    var coachStep: CoachStep = .idle
    var coachLine = ""
    var coachLineID = 0


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
    /// One line at a time. `MissionSvc` owns the pacing and the queue,
    /// so a new beat can never wipe an important one off the screen.
    var missionDialogueText = ""
    var missionDialogueID = 0
    var missionDialogueVisible = false

    let missionMangoTarget = 3
    
    var eatAnimationID = 0
    var eatAnimationVisible = false
    
    var showMissionCompleteCard = false
    
    var showQuiz = false
    var quizTransitionID = 0

    var quizAnswered = false
    var quizCorrect = false
}
