//
//  CoachSvcTests.swift
//  POCTests
//
//  Created by Shan Newcastle on 07/09/26.
//

import Foundation
import Testing

@testable import SonicPals

/// A real `ECSWorld` listens for global notifications, which made these
/// tests hostage to whatever else was running
@MainActor
final class FakeCoachHost: CoachHost {
    let model = AppModel()

    private(set) var teaching = false
    private(set) var huntStarted = false

    /// Recorded live, so tests need not catch a step mid-flight
    private(set) var beats: [(step: CoachStep, teaching: Bool)] = []

    func setTeaching(_ on: Bool) {
        teaching = on
    }

    func startHunt() {
        huntStarted = true
    }

    func playCoachCue() {
        beats.append((model.coachStep, teaching))
    }

    var steps: [CoachStep] {
        beats.map(\.step)
    }
}

@Suite("Coach")
struct CoachSvcTests {
    private let host = FakeCoachHost()
    private let coach = CoachSvc(beat: .milliseconds(20))

    init() {
        coach.attach(to: host)
    }

    private var model: AppModel { host.model }

    /// The script runs on a task, nothing lands synchronously
    private func tick() async {
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(2))
    }

    /// Waits on state, not the clock, since tests share the main actor
    private func wait(for step: CoachStep) async {
        await wait { model.coachStep == step }
    }

    private func wait(until predicate: () -> Bool) async {
        for _ in 0..<500 where !predicate() {
            await tick()
        }
    }

    // MARK: - Scan

    @Test("Coaching starts by pointing the player at the floor")
    func startsAtTheFloor() async {
        defer { coach.suspend() }

        coach.noteSessionReady()
        await wait { host.steps.count >= 1 }

        #expect(host.steps.first == .lookDown)
        #expect(!model.coachLine.isEmpty)
    }

    @Test("It does not re-introduce Battiw, who has already said hello")
    func doesNotSayHelloAgain() async {
        defer { coach.suspend() }

        coach.noteSessionReady()
        await wait { host.steps.count >= 1 }

        #expect(!model.coachLine.lowercased().contains("i'm battiw"))
    }

    @Test("Then it asks for the sweep")
    func asksForTheSweep() async {
        defer { coach.suspend() }

        coach.noteSessionReady()
        await wait { host.steps.count >= 2 }

        #expect(host.steps == [.lookDown, .fillRing])
    }

    @Test("Once the sweep is moving it gets out of the way")
    func clearsOnceScanning() async {
        defer { coach.suspend() }

        coach.noteSessionReady()
        await wait(for: .fillRing)

        coach.noteScan(progress: 0.4)

        #expect(model.coachStep == .idle)
        #expect(model.coachLine.isEmpty)
    }

    @Test("A twitch of the phone is not the sweep starting")
    func tinyProgressDoesNotClear() async {
        defer { coach.suspend() }

        coach.noteSessionReady()
        await wait(for: .fillRing)

        coach.noteScan(progress: 0.01)

        #expect(model.coachStep == .fillRing)
    }

    @Test("The session only starts the script once")
    func sessionReadyIsIdempotent() async {
        defer { coach.suspend() }

        coach.noteSessionReady()
        await wait(for: .fillRing)
        coach.noteScan(progress: 0.5)

        coach.noteSessionReady()

        #expect(model.coachStep == .idle)
    }

    // MARK: - Teaching echolocation

    @Test("The lesson opens on the dark, not on the button")
    func lessonOpensOnTheDark() async {
        defer { coach.suspend() }

        coach.noteMissionStart()
        await wait { host.steps.count >= 1 }

        #expect(host.steps.first == .dark)
    }

    @Test("The whole lesson runs before the button is offered")
    func lessonRunsBeforeThePing() async {
        defer { coach.suspend() }

        coach.noteMissionStart()
        await wait(for: .ping)

        #expect(host.steps == [.dark, .squeak, .bounce, .echo, .goal, .ping])
    }

    @Test(
        "Every teaching beat holds the controls shut",
        arguments: [
            CoachStep.lookDown,
            .fillRing,
            .dark,
            .squeak,
            .bounce,
            .echo,
            .goal
        ]
    )
    func teachingLocksInput(step: CoachStep) {
        #expect(step.locksInput)
    }

    @Test(
        "Once the player is being asked to do something, it does not",
        arguments: [
            CoachStep.idle,
            .ping,
            .sawEcho,
            .colours,
            .hold,
            .hunt,
            .eat
        ]
    )
    func doingDoesNotLockInput(step: CoachStep) {
        #expect(!step.locksInput)
    }

    @Test("The teaching lock reaches the host, then lifts")
    func teachingLockReachesTheHost() async {
        defer { coach.suspend() }

        coach.noteMissionStart()
        await wait(for: .ping)

        let lesson = host.beats.filter { $0.step != .ping }

        #expect(lesson.allSatisfy { $0.teaching })
        #expect(host.beats.last?.teaching == false)
        #expect(!host.teaching)
    }

    @Test("The lesson is taught once, not on every mission")
    func lessonIsTaughtOnce() async {
        defer { coach.suspend() }

        coach.noteMissionStart()
        await wait(for: .ping)

        coach.noteMissionStart()

        #expect(model.coachStep == .ping)
    }

    // MARK: - Explaining the echo

    @Test("The first ping is explained, starting with what just happened")
    func firstPingIsExplained() async {
        defer { coach.suspend() }

        coach.notePing()
        await wait { host.steps.count >= 1 }

        #expect(host.steps.first == .sawEcho)
    }

    @Test("The colours are explained while the player can still ping")
    func coloursAreExplainedLive() async {
        defer { coach.suspend() }

        coach.notePing()
        await wait { host.steps.contains(.colours) }

        // Live controls: they can ping again while it is explained
        #expect(host.beats.allSatisfy { !$0.teaching })
        #expect(host.steps.contains(.colours))
    }

    @Test("The explanation ends by starting the hunt")
    func explanationStartsTheHunt() async {
        defer { coach.suspend() }

        coach.notePing()
        await wait(for: .hunt)
        await wait { host.huntStarted }

        #expect(model.coachStep == .idle)
        #expect(model.coachLine.isEmpty)
        #expect(host.huntStarted)
    }

    @Test("An abandoned lesson does not go on to start the hunt")
    func abandonedLessonDoesNotStartTheHunt() async {
        // Long enough that the script cannot finish on its own
        let slow = CoachSvc(beat: .seconds(30))
        slow.attach(to: host)

        slow.notePing()
        await wait { host.steps.count >= 1 }

        slow.suspend()

        for _ in 0..<20 {
            await tick()
        }

        #expect(!host.huntStarted)
    }

    @Test("Only the first ping is explained")
    func laterPingsAreQuiet() async {
        defer { coach.suspend() }

        coach.notePing()
        await wait(for: .hunt)
        await wait { model.coachStep == .idle }

        coach.notePing()

        #expect(model.coachStep == .idle)
    }

    // MARK: - Eating

    @Test("The first mango in reach is pointed out")
    func firstMangoIsPointedOut() {
        coach.noteEatReady()

        #expect(model.coachStep == .eat)
        #expect(model.coachStep.spotlight == .eat)
    }

    @Test("The eat prompt waits for the player rather than timing out")
    func eatPromptWaits() async {
        coach.noteEatReady()

        for _ in 0..<40 {
            await tick()
        }

        #expect(model.coachStep == .eat)
    }

    @Test("Eating finishes the coaching for good")
    func eatingFinishesCoaching() {
        coach.noteEatReady()
        coach.noteEaten()

        #expect(coach.isDone)
        #expect(model.coachStep == .idle)
    }

    @Test("Coaching does not restart after it is done")
    func doneStaysDone() {
        coach.noteEatReady()
        coach.noteEaten()

        coach.noteEatReady()

        #expect(model.coachStep == .idle)
    }

    // MARK: - Spotlight

    @Test(
        "The spotlight points at the control being asked for",
        arguments: [
            (CoachStep.ping, CoachTarget.ping),
            (.hold, .ping),
            (.eat, .eat),
            (.dark, .none),
            (.idle, .none),
            (.sawEcho, .none)
        ]
    )
    func spotlightTargets(step: CoachStep, expected: CoachTarget) {
        #expect(step.spotlight == expected)
    }

    // MARK: - Teardown

    @Test("Suspending a lesson lifts the lock it was holding")
    func suspendLiftsTheLock() async {
        coach.noteMissionStart()
        await wait { host.steps.count >= 1 }

        #expect(host.teaching)

        coach.suspend()

        // Cancelling alone would strand the flag
        #expect(!host.teaching)
        #expect(model.coachStep == .idle)
    }
}
