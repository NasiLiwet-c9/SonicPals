//
//  CoachSvc.swift
//  POC
//
//  Created by Shan Newcastle on 04/09/26.
//

import Foundation

/// What the coach is showing right now. `.idle` is nothing.
enum CoachStep: Equatable {
    case idle

    // Scan
    case lookDown
    case fillRing

    // How echolocation works — the point of the game
    case dark
    case squeak
    case bounce
    case echo
    case goal

    // Controls, and what the echo actually shows
    case ping
    case sawEcho
    case colours
    case hold
    case hunt
    case eat

    /// Which control the coach is pointing at, if any.
    var spotlight: CoachTarget {
        switch self {
        case .ping, .hold: .ping
        case .eat: .eat
        default: .none
        }
    }

    /// While Battiw is explaining how echolocation works, the controls
    /// are held shut so a child cannot skip past it. Once they have
    /// pinged, the lock comes off — the rest is explained *while* they
    /// play with it, which is the part that actually teaches.
    var locksInput: Bool {
        switch self {
        case .idle, .ping, .sawEcho, .colours, .hold, .hunt, .eat: false
        default: true
        }
    }
}

/// The control a beat is pointing at.
enum CoachTarget {
    case none
    case ping
    case eat
}

/// Teaches the game while the game is running.
///
/// Beats fire off what the player actually did — the session coming up,
/// the scan filling, the first ping, the first mango in reach — so the
/// camera never leaves the screen.
///
/// The echolocation beats come before the ping button is usable: the game
/// is meant to teach how bats see with sound, and a child who taps first
/// learns nothing.
@MainActor
final class CoachSvc {
    private unowned var world: ECSWorld!

    private var task: Task<Void, Never>?

    private var scanned = false
    private var taught = false
    private var pinged = false
    private var ate = false
    private var finished = false

    private var model: AppModel { world.model }

    /// Long enough to read a short line aloud, short enough not to stall.
    private let beat = Duration.milliseconds(2600)

    func attach(to world: ECSWorld) {
        self.world = world
    }

    var isDone: Bool { finished }

    // MARK: - Events

    func noteSessionReady() {
        guard !scanned else { return }

        scanned = true

        run {
            await self.beat(.lookDown, "Look down at the floor!")
            self.set(.fillRing, "Fill the ring! Look around.")
        }
    }

    func noteScan(progress: Float) {
        guard model.coachStep == .fillRing, progress > 0.10 else { return }

        // The percentage and the turn arrows take it from here.
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

            self.set(.ping, "Your turn. Tap to squeak!")
        }
    }

    func notePing() {
        guard !pinged else { return }

        pinged = true

        // Input stays live through this: they can keep pinging and watch
        // the colours change while Battiw explains what they mean.
        run {
            await self.beat(.sawEcho, "Whoa! That's my echo.")
            await self.beat(.colours, "Red is close. Blue is far!")
            await self.beat(.hold, "Hold it down for more!")
            await self.beat(.hunt, "Now find the tree. A buzz means close!")

            self.clear()
            self.world.mission.startHunt()
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

    /// Stops a lesson and lifts the teaching lock. `cancel` alone would
    /// leave the flag set, which silences guidance for the rest of the
    /// run.
    func suspend() {
        cancel()
        clear()
    }

    // MARK: - Beats

    private func run(_ body: @escaping () async -> Void) {
        cancel()
        task = Task { @MainActor in await body() }
    }

    /// Shows a line and waits it out.
    private func beat(_ step: CoachStep, _ line: String) async {
        guard !Task.isCancelled else { return }

        set(step, line)

        try? await Task.sleep(for: beat)
    }

    private func set(_ step: CoachStep, _ line: String) {
        model.coachStep = step
        model.coachLine = line
        model.coachLineID += 1

        world.setTeaching(step.locksInput)
        world.sfx.dialogue()
    }

    private func clear() {
        model.coachStep = .idle
        model.coachLine = ""

        world.setTeaching(false)
    }
}
