//
//  MissionSvcTests.swift
//  POCTests
//
//  Created by Shan Newcastle on 07/09/26.
//

import Foundation
import Testing

@testable import POC

/// Spawning is a no-op without LiDAR, so this covers the bookkeeping
@Suite("Mission")
struct MissionSvcTests {
    private let world = ECSWorld()

    private var mission: MissionSvc { world.mission }
    private var model: AppModel { world.model }

    private func tick() async {
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(2))
    }

    private func wait(until predicate: () -> Bool) async {
        for _ in 0..<300 where !predicate() {
            await tick()
        }
    }

    /// `begin` starts the lesson too, and both hold the world unowned
    private func stop() {
        world.coach.suspend()
        mission.cancel()
        mission.dismissDialogue()
    }

    // MARK: - Starting

    @Test("Beginning a run resets the score and lights the dark")
    func beginResetsTheRun() {
        defer { stop() }

        model.mangoEatenCount = 2
        model.missionComplete = true

        mission.begin()

        #expect(model.missionStarted)
        #expect(!model.missionComplete)
        #expect(model.mangoEatenCount == 0)
        #expect(model.dimOn)
    }

    @Test("A run already under way is not restarted")
    func beginIsIdempotent() {
        defer { stop() }

        mission.begin()
        model.mangoEatenCount = 2

        mission.begin()

        #expect(model.mangoEatenCount == 2)
    }

    @Test("The first run holds the hunt back for the lesson")
    func firstRunWaitsForTheLesson() {
        defer { stop() }

        #expect(!world.coach.isDone)

        mission.begin()

        #expect(world.targetEntity == nil)
    }

    // MARK: - Progress

    @Test("Eating a mango short of the goal keeps the run going")
    func partialProgressKeepsGoing() {
        defer { stop() }

        mission.begin()
        model.mangoEatenCount = 1

        mission.advance()

        #expect(!model.missionComplete)
    }

    @Test("Eating the last mango ends the run")
    func lastMangoEndsTheRun() {
        defer { stop() }

        mission.begin()
        model.mangoEatenCount = model.missionMangoTarget

        mission.advance()

        #expect(model.missionComplete)
    }

    @Test("Overshooting the goal still ends the run")
    func overshootEndsTheRun() {
        defer { stop() }

        mission.begin()
        model.mangoEatenCount = model.missionMangoTarget + 1

        mission.advance()

        #expect(model.missionComplete)
    }

    @Test("Finishing brings up the completion card, after a beat")
    func finishShowsTheCard() async {
        defer { stop() }

        mission.begin()
        model.mangoEatenCount = model.missionMangoTarget

        mission.advance()

        #expect(!model.showMissionCompleteCard)

        await wait { model.showMissionCompleteCard }

        #expect(model.showMissionCompleteCard)
    }

    @Test("A run abandoned before the card appears does not show it")
    func abandonedRunShowsNoCard() async {
        defer { stop() }

        mission.begin()
        model.mangoEatenCount = model.missionMangoTarget
        mission.advance()

        // The player backed out to the menu
        model.missionComplete = false

        for _ in 0..<40 {
            await tick()
        }

        #expect(!model.showMissionCompleteCard)
    }

    // MARK: - What Battiw may say

    @Test(
        "Battiw only speaks during a run that is still going",
        arguments: [
            (AppModel.HUDStage.mission, false, CoachStep.idle, true),
            (.scanning, false, .idle, false),
            (.transitioning, false, .idle, false),
            (.mission, true, .idle, false),          // run already over
            (.mission, false, .dark, false),         // mid-lesson
            (.mission, false, .goal, false),         // mid-lesson
            (.mission, false, .ping, true),          // lesson done asking
            (.mission, false, .eat, true)
        ]
    )
    func speaksOnlyWhenItShould(
        stage: AppModel.HUDStage,
        complete: Bool,
        coachStep: CoachStep,
        expected: Bool
    ) {
        #expect(
            MissionSvc.canSpeak(
                stage: stage,
                complete: complete,
                coachStep: coachStep
            ) == expected
        )
    }

    @Test("Finding the tree is announced during the mission")
    func foundTreeIsAnnounced() async {
        defer { stop() }

        model.hudStage = .mission
        model.coachStep = .idle
        mission.dismissDialogue()

        mission.showFoundTreeDialogue()

        await wait { model.missionDialogueVisible }

        #expect(model.missionDialogueVisible)
        #expect(!model.missionDialogueText.isEmpty)
    }

    @Test("Dismissing clears the bubble")
    func dismissClearsTheBubble() async {
        defer { stop() }

        model.hudStage = .mission
        mission.showFoundTreeDialogue()

        await wait { model.missionDialogueVisible }

        mission.dismissDialogue()

        #expect(!model.missionDialogueVisible)
    }

    @Test("A new line does not wipe the one already showing")
    func linesQueueRatherThanClobber() async {
        defer { stop() }

        model.hudStage = .mission
        model.coachStep = .idle
        mission.dismissDialogue()

        mission.show(.sensed)
        await wait { model.missionDialogueVisible }

        let first = model.missionDialogueText

        // A cue landing mid-sentence used to overwrite the line under it
        mission.show(.close)

        #expect(model.missionDialogueText == first)
    }

    // MARK: - The hunt

    @Test("The hunt does not start before the run does")
    func huntNeedsARun() {
        defer { stop() }

        mission.startHunt()

        #expect(!model.missionStarted)
    }
}
