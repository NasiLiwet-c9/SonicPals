//
//  DialogueViewModel.swift
//  POC
//
//  Created by James Richard Renaldo on 17/08/26.
//

import Foundation
import Observation

/// Walks dialogue lines one at a time. Lines appear whole, the views
/// pop them in, keyed on ``currentLineIndex``, advance after
/// ``autoAdvance``, and skip on tap
@MainActor
@Observable
final class DialogueViewModel {
    private(set) var currentLineIndex = 0

    let lines: [String]
    let loops: Bool

    /// `nil` waits for a tap instead
    let autoAdvance: Duration?

    @ObservationIgnored var onFinishedAllLines: (() -> Void)?

    @ObservationIgnored private let sfx = SfxSvc.shared
    @ObservationIgnored private var holdTask: Task<Void, Never>?

    var visibleText: String {
        lines.indices.contains(currentLineIndex)
            ? lines[currentLineIndex]
            : ""
    }

    init(
        lines: [String],
        loops: Bool = false,
        autoAdvance: Duration? = nil,
        onFinishedAllLines: (() -> Void)? = nil
    ) {
        self.lines = lines
        self.loops = loops
        self.autoAdvance = autoAdvance
        self.onFinishedAllLines = onFinishedAllLines
    }

    func start() {
        currentLineIndex = 0
        showCurrentLine()
    }

    func advance() {
        sfx.tap()
        goToNextLine()
    }

    func stop() {
        holdTask?.cancel()
        holdTask = nil
    }

    private func showCurrentLine() {
        guard lines.indices.contains(currentLineIndex) else { return }

        sfx.dialogue()

        holdTask?.cancel()

        guard let autoAdvance else { return }

        holdTask = Task { [weak self] in
            try? await Task.sleep(for: autoAdvance)

            guard !Task.isCancelled else { return }

            self?.goToNextLine()
        }
    }

    private func goToNextLine() {
        let nextIndex = currentLineIndex + 1

        if lines.indices.contains(nextIndex) {
            currentLineIndex = nextIndex
            showCurrentLine()
            return
        }

        if loops, !lines.isEmpty {
            currentLineIndex = 0
            showCurrentLine()
            return
        }

        holdTask?.cancel()
        onFinishedAllLines?()
    }
}
