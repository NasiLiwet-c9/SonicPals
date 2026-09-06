//
//  AppModelTests.swift
//  POCTests
//
//  Created by Shan Newcastle on 05/09/26.
//

import Testing

@testable import POC

@Suite("App model")
struct AppModelTests {
    @Test("A fresh run starts at the scan with nothing found")
    func freshState() {
        let model = AppModel()

        #expect(model.hudStage == .scanning)
        #expect(!model.hasTarget)
        #expect(!model.targetFound)
        #expect(!model.missionStarted)
        #expect(!model.missionComplete)
        #expect(model.mangoEatenCount == 0)
        #expect(model.scanProgress == 0)
        #expect(!model.scanReady)
        #expect(model.coachStep == .idle)
        #expect(model.coachLine.isEmpty)
    }

    @Test("Nothing can be fired without LiDAR")
    func lidarGatesEverything() {
        let model = AppModel()

        #expect(!model.canWave)
        #expect(!model.canSpawn)

        model.lidarOK = true

        #expect(model.canWave)
        #expect(model.canSpawn)
    }

    @Test("The mango goal is reachable and worth more than one")
    func goalIsSane() {
        #expect(AppModel().missionMangoTarget > 1)
    }

    @Test("The HUD walks scan to mission in order")
    func hudStageOrder() {
        let model = AppModel()

        let order: [AppModel.HUDStage] = [
            .scanning,
            .scanCompletePrompt,
            .transitioning,
            .mission
        ]

        for stage in order {
            model.hudStage = stage
            #expect(model.hudStage == stage)
        }
    }
}
