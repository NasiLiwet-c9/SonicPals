//
//  MissionSvc.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import Foundation
import RealityKit

/// Runs the "find three mangoes" quest: dialogue, when the next tree is
/// requested, and when the run is over.
///
/// Split from `ECSWorld`, which owns the AR session and the scene.
@MainActor
final class MissionSvc {
    private unowned var world: ECSWorld!

    /// The one in-flight mission step, spawn retry or bite pause.
    private var task: Task<Void, Never>?

    private var model: AppModel { world.model }

    func attach(to world: ECSWorld) {
        self.world = world
    }

    // MARK: - Lifecycle

    func begin() {
        guard !model.missionStarted else { return }

        cancel()

        model.missionStarted = true
        model.missionComplete = false
        model.mangoEatenCount = 0
        model.dimOn = true
        world.lastTargetPos = nil

        // First run, the coach covers this over the live camera and holds
        // the hunt back until the lesson is done — see `startHunt`.
        if world.coach.isDone {
            say(["Let's find \(model.missionMangoTarget) more mangoes!"])
            spawnNextTarget(delayMs: 120)
        }

        world.coach.noteMissionStart()

#if DEBUG
        print("[MISSION DEBUG] MISSION STARTED")
#endif
    }

    func restart() async {
        cancel()
        world.clear()

        model.showMissionCompleteCard = false
        model.showQuiz = false
        model.quizAnswered = false
        model.quizCorrect = false
        model.quizTransitionID = 0

        model.missionDialogueVisible = false
        model.missionComplete = false
        model.missionStarted = false
        model.mangoEatenCount = 0
        model.eatAnimationVisible = false

        model.missionDark = false
        model.dimOn = false
        model.waveSeq = 0

        model.scanReady = false
        model.scanProgress = 0
        model.scanTurn = .none
        model.hudStage = .scanning

        await world.start()

        guard model.lidarOK else { return }

        world.sfx.sessionBgm()

#if DEBUG
        print("[MISSION DEBUG] MISSION RESTARTED")
#endif
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    // MARK: - Progress

    /// Holds off tree removal until the bite animation has played.
    func completeBite(removing eaten: Entity?) {
        cancel()

        task = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(500))

            guard let self, !Task.isCancelled else { return }

            eaten?.removeFromParent()
            advance()
        }
    }

    func advance() {
        let eaten = model.mangoEatenCount
        let goal = model.missionMangoTarget

        if eaten >= goal {
            finish(eaten: eaten, goal: goal)
            return
        }

        say(
            eaten == 1
                ? ["Yum! One down.", "Find the next tree!"]
                : ["One mango left!"],
            hold: Self.goalBeat,
            interrupt: true
        )

#if DEBUG
        print("[MISSION DEBUG] REQUESTING TREE \(eaten + 1)/\(goal)")
#endif

        spawnNextTarget(delayMs: 450)
    }

    private func finish(eaten: Int, goal: Int) {
        cancel()

        dismissDialogue()
        model.missionComplete = true

        // Final mango success sound plays immediately.
        world.sfx.missionDone()
        world.sfx.stopBgm()

        world.clearActiveWave()
        world.clearTraces()

        // Wait 0.5 seconds after Mango 3 before showing completion.
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(500))

            guard let self, model.missionComplete else { return }

            model.showMissionCompleteCard = true
        }

#if DEBUG
        print("[MISSION DEBUG] MISSION COMPLETE \(eaten)/\(goal)")
#endif
    }

    // MARK: - Dialogue

    private struct Beat {
        let lines: [String]
        let hold: Duration
    }

    /// Everything Battiw says queues here. Writing to the model directly
    /// meant a cue firing mid-sentence wiped the line underneath it.
    private var queue: [Beat] = []
    private var speakTask: Task<Void, Never>?

    /// Bumped when a run is abandoned, so a cancelled run cannot clear
    /// the handle of the run that replaced it.
    private var speakGen = 0

    nonisolated static let beat = Duration.milliseconds(2400)

    /// New-goal lines earn a longer look.
    nonisolated static let goalBeat = Duration.milliseconds(4800)

    func dismissDialogue() {
        stopSpeaking()
        model.missionDialogueVisible = false
    }

    private func stopSpeaking() {
        speakGen += 1
        speakTask?.cancel()
        speakTask = nil
        queue.removeAll()
    }

    func showFoundTreeDialogue() {
        guard canSpeak else { return }

        // Cuts in: waiting out a now-stale "close" cue would delay the
        // one line the player must not miss.
        say(
            ["Now find the mango!"],
            hold: Self.goalBeat,
            interrupt: true
        )

#if DEBUG
        print("[MISSION DEBUG] TREE FOUND — FIND MANGO")
#endif
    }

    func show(_ cue: TargetCue) {
        guard canSpeak else { return }

        switch cue {
        case .sensed:
            say([
                "Something echoed back!",
                "Follow my arrow!"
            ])

        case .close:
            say(["Found the tree! Move closer!"])
        }
    }

    private var canSpeak: Bool {
        model.hudStage == .mission
            && !model.missionComplete
            && !model.coachStep.locksInput
    }

    /// `interrupt` drops anything queued or mid-sentence.
    private func say(
        _ lines: [String],
        hold: Duration = MissionSvc.beat,
        interrupt: Bool = false
    ) {
        if interrupt {
            stopSpeaking()
        }

        queue.append(Beat(lines: lines, hold: hold))

        guard speakTask == nil else { return }

        let gen = speakGen

        speakTask = Task { @MainActor [weak self] in
            await self?.drain(gen: gen)
        }
    }

    /// Walks the queue one line at a time, skipping nothing.
    private func drain(gen: Int) async {
        defer {
            if gen == speakGen {
                speakTask = nil
                model.missionDialogueVisible = false
            }
        }

        while !queue.isEmpty {
            let beat = queue.removeFirst()

            for line in beat.lines {
                guard !Task.isCancelled else { return }

                model.missionDialogueText = line
                model.missionDialogueID += 1
                model.missionDialogueVisible = true

                world.sfx.dialogue()

                try? await Task.sleep(for: beat.hold)

                guard !Task.isCancelled else { return }
            }
        }
    }

    // MARK: - Spawning

    /// Starts the hunt once the coach has finished teaching.
    func startHunt() {
        guard model.missionStarted, world.targetEntity == nil else { return }

        spawnNextTarget(delayMs: 120)
    }

    /// Used by the respawn button.
    func requestTarget() {
        if canSpeak {
            say(["Let me listen again...", "Look around for a new spot!"])
        }

        spawnNextTarget(delayMs: 200)
    }

    /// Retries until a safe pose turns up.
    private func spawnNextTarget(delayMs: Int) {
        cancel()

        task = Task { @MainActor [weak self] in
            guard let self else { return }

            try? await Task.sleep(for: .milliseconds(delayMs))

            var attempt = 0

            while !Task.isCancelled,
                  model.missionStarted,
                  !model.missionComplete,
                  model.mangoEatenCount < model.missionMangoTarget,
                  world.targetEntity == nil {
                attempt += 1

#if DEBUG
                print("[MISSION DEBUG] SPAWN RETRY \(attempt)")
#endif

                let spawned = await world.spawnTargetNow(showError: false)

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
        targetEntity: \(world.targetEntity != nil ? "YES" : "NO")
        model.hasTarget: \(model.hasTarget)
        eaten: \(model.mangoEatenCount)/\(model.missionMangoTarget)
        """)

        if let targetEntity = world.targetEntity {
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
