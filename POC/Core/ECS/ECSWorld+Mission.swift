//
//  ECSWorld+Mission.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import Foundation
import RealityKit

extension ECSWorld {
    func beginMission() {
        guard !model.missionStarted else { return }

        missionTask?.cancel()
        missionTask = nil

        model.missionStarted = true
        model.missionComplete = false
        model.mangoEatenCount = 0
        model.dimOn = true
        lastTargetPos = nil

        showMissionDialogue([
            "I sense there are \(model.missionMangoTarget) mango here, let's find them.",
            "Use the button below to help me find those mangoes."
        ])

#if DEBUG
        print("[MISSION DEBUG] MISSION STARTED")
#endif

        spawnNextTarget(delayMs: 120)
    }

    func dismissMissionDialogue() {
        model.missionDialogueVisible = false
    }

    func showFoundTreeDialogue() {
        guard model.hudStage == .mission, !model.missionComplete else { return }

        showMissionDialogue([
            "Great! You found the tree. Now find the mango!"
        ])

#if DEBUG
        print("[MISSION DEBUG] TREE FOUND — FIND MANGO")
#endif
    }

    func advanceMission() {
        let eaten = model.mangoEatenCount
        let goal = model.missionMangoTarget

        if eaten >= goal {
            missionTask?.cancel()
            missionTask = nil
            model.missionComplete = true

            sfx.complete()

//            showMissionDialogue([
//                "Great job! You found all \(goal) mangoes!",
//                "I'm full now, it's time to go home...."
//            ])

#if DEBUG
            print("[MISSION DEBUG] MISSION COMPLETE \(eaten)/\(goal)")
#endif
            return
        }

        showMissionDialogue(
            eaten == 1
                ? ["Great! One mango down. Let's search for another tree!"]
                : ["Nice! One more mango. Let's find the last tree!"]
        )

#if DEBUG
        print("[MISSION DEBUG] REQUESTING TREE \(eaten + 1)/\(goal)")
#endif

        spawnNextTarget(delayMs: 450)
    }

    func restartMission() async {
        missionTask?.cancel()
        missionTask = nil
        clear()

        model.showMissionCompleteCard = false
        model.showQuiz = false
        model.quizAnswered = false
        model.quizCorrect = false
        model.quizTransitionID = 0
        model.missionDialogueVisible = false
        model.missionComplete = false
        model.missionStarted = false
        model.mangoEatenCount = 0
        model.hudStage = .scanning

        await start()

//        guard model.lidarOK else { return }
//
//        endScan()
//
//        try? await Task.sleep(for: .milliseconds(300))
//
//        model.hudStage = .mission
//        beginMission()

#if DEBUG
        print("[MISSION DEBUG] MISSION RESTARTED")
#endif
    }

    private func showMissionDialogue(_ lines: [String]) {
        model.missionDialogueLines = lines
        model.missionDialogueID += 1
        model.missionDialogueVisible = true
    }

    private func spawnNextTarget(delayMs: Int) {
        missionTask?.cancel()

        missionTask = Task { @MainActor [weak self] in
            guard let self else { return }

            try? await Task.sleep(for: .milliseconds(delayMs))

            var attempt = 0

            while !Task.isCancelled,
                  model.missionStarted,
                  !model.missionComplete,
                  model.mangoEatenCount < model.missionMangoTarget,
                  targetEntity == nil {
                attempt += 1

#if DEBUG
                print("[MISSION DEBUG] SPAWN RETRY \(attempt)")
#endif

                let spawned = await spawnTargetNow(showError: false)

                if spawned {
#if DEBUG
                    print("[MISSION DEBUG] TARGET SPAWNED")
                    debugTargetState()
#endif
                    return
                }

#if DEBUG
                print("[MISSION DEBUG] NO SAFE TARGET YET")
#endif

                try? await Task.sleep(
                    for: .milliseconds(TargetCfg.Preflight.retryMs)
                )
            }

#if DEBUG
            if Task.isCancelled {
                print("[MISSION DEBUG] SPAWN TASK CANCELLED")
            }
#endif
        }
    }

#if DEBUG
    private func debugTargetState() {
        print("""
        [TARGET DEBUG]
        targetEntity: \(targetEntity != nil ? "YES" : "NO")
        model.hasTarget: \(model.hasTarget)
        eaten: \(model.mangoEatenCount)/\(model.missionMangoTarget)
        """)

        if let targetEntity {
            let p = targetEntity.position(relativeTo: nil)

            print(String(
                format: "[TARGET DEBUG] worldPos x=%.2f y=%.2f z=%.2f",
                p.x,
                p.y,
                p.z
            ))
        }
    }
#endif
}
