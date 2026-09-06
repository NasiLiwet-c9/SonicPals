//
//  CoachSvc.swift
//  POC
//
//  Created by Shan Newcastle on 04/09/26.
//

import Foundation

/// Current beat, `.idle` is nothing showing
enum CoachStep: Equatable {
    case idle

    // Scan
    case lookDown
    case fillRing

    // The echolocation lesson
    case dark
    case squeak
    case bounce
    case echo
    case goal

    // Controls
    case ping
    case sawEcho
    case colours
    case hold
    case hunt
    case eat

    /// Which control the coach is pointing at, if any
    var spotlight: CoachTarget {
        switch self {
        case .ping, .hold: .ping
        case .eat: .eat
        default: .none
        }
    }

    /// Shut until the lesson is done, so it cannot be skipped past
    var locksInput: Bool {
        switch self {
        case .idle, .ping, .sawEcho, .colours, .hold, .hunt, .eat: false
        default: true
        }
    }
}

/// A protocol, not `ECSWorld`, so the script can be tested on its own
@MainActor
protocol CoachHost: AnyObject {
    var model: AppModel { get }

    /// Keeps guidance quiet while a lesson runs
    func setTeaching(_ on: Bool)

    /// Spawns the first tree once the lesson ends
    func startHunt()

    func playCoachCue()
}

/// The control a beat points at
enum CoachTarget {
    case none
    case ping
    case eat
}

/// Teaches the game while it runs, off what the player just did
///
/// The lesson comes before the ping button works, since a child who taps
/// first learns nothing
@MainActor
final class CoachSvc {
    private unowned var host: (any CoachHost)!

    private var task: Task<Void, Never>?

    private var scanned = false
    private var taught = false
    private var pinged = false
    private var ate = false
    private var finished = false

    private var model: AppModel { host.model }

    /// Injectable so tests need not wait the script out
    private let beat: Duration

    init(beat: Duration = .milliseconds(2600)) {
        self.beat = beat
    }

    func attach(to host: any CoachHost) {
        self.host = host
    }

    var isDone: Bool { finished }

    // MARK: - Events

    func noteSessionReady() {
        guard !scanned else { return }

        scanned = true

        run {
            await self.beat(.lookDown, "Look down at the floor!")

            guard !Task.isCancelled else { return }

            self.set(.fillRing, "Fill the ring! Look around.")
        }
    }

    func noteScan(progress: Float) {
        guard model.coachStep == .fillRing, progress > 0.10 else { return }

        // The percentage and arrows take over
        clear()
    }

    func noteMissionStart() {
        guard !taught else { return }

        taught = true

        run {
            await self.beat(.dark, "It's pitch dark in here!")
            await self.beat(.squeak, "So I squeak, super high!")
            await self.beat(.bounce, "It bounces off things...")
            await self.beat(.echo, "...and back as an echo!")
            await self.beat(.goal, "Echoes help me see! Find 3 mangoes.")

            guard !Task.isCancelled else { return }

            self.set(.ping, "Your turn. Tap to squeak!")
        }
    }

    func notePing() {
        guard !pinged else { return }

        pinged = true

        // Input stays live, so they can ping while it is explained
        run {
            await self.beat(.sawEcho, "Whoa! That's my echo.")
            await self.beat(.colours, "Red is close. Blue is far!")
            await self.beat(.hold, "Hold it down for more!")
            await self.beat(.hunt, "Now find the tree. A buzz means close!")

            guard !Task.isCancelled else { return }

            self.clear()
            self.host.startHunt()
        }
    }

    func noteEatReady() {
        guard !ate, !finished else { return }

        ate = true
        set(.eat, "Tap to munch it!")
    }

    func noteEaten() {
        guard model.coachStep == .eat else { return }

        finished = true
        clear()
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    /// `cancel` alone leaves the lock set, killing guidance for the run
    func suspend() {
        cancel()
        clear()
    }

    // MARK: - Beats

    private func run(_ body: @escaping () async -> Void) {
        cancel()
        task = Task { @MainActor in await body() }
    }

    private func beat(_ step: CoachStep, _ line: String) async {
        guard !Task.isCancelled else { return }

        set(step, line)

        try? await Task.sleep(for: beat)
    }

    private func set(_ step: CoachStep, _ line: String) {
        model.coachStep = step
        model.coachLine = line
        model.coachLineID += 1

        host.setTeaching(step.locksInput)
        host.playCoachCue()
    }

    private func clear() {
        model.coachStep = .idle
        model.coachLine = ""

        host.setTeaching(false)
    }
}
