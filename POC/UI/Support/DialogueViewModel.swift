//
//  DialogueBubbleViewModel.swift
//  POC
//
//  Created by James Richard Renaldo on 17/08/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class DialogueViewModel: ObservableObject {
    @Published private(set) var visibleText: String = ""
    @Published private(set) var isLineFullyTyped = false
    @Published private(set) var currentLineIndex = 0

    let lines: [String]
    var typingSpeed: Double
    var onFinishedAllLines: (() -> Void)?

    private let sfx = SfxSvc.shared
    private var typingTask: Task<Void, Never>?

    init(
        lines: [String],
        typingSpeed: Double = 0.03,
        onFinishedAllLines: (() -> Void)? = nil
    ) {
        self.lines = lines
        self.typingSpeed = typingSpeed
        self.onFinishedAllLines = onFinishedAllLines
    }

    func start() {
        currentLineIndex = 0
        typeCurrentLine()
    }

    func advance() {
        sfx.tap()

        if isLineFullyTyped {
            goToNextLine()
        } else {
            revealFullLine()
        }
    }

    private func typeCurrentLine() {
        guard lines.indices.contains(currentLineIndex) else { return }

        let line = lines[currentLineIndex]

        visibleText = ""
        isLineFullyTyped = false

        sfx.dialogue()

        typingTask?.cancel()
        typingTask = Task {
            for character in line {
                if Task.isCancelled { return }

                try? await Task.sleep(for: .seconds(typingSpeed))

                if Task.isCancelled { return }

                visibleText.append(character)
            }

            isLineFullyTyped = true
        }
    }

    private func revealFullLine() {
        guard lines.indices.contains(currentLineIndex) else { return }

        typingTask?.cancel()
        visibleText = lines[currentLineIndex]
        isLineFullyTyped = true
    }

    private func goToNextLine() {
        let nextIndex = currentLineIndex + 1

        if lines.indices.contains(nextIndex) {
            currentLineIndex = nextIndex
            typeCurrentLine()
        } else {
            onFinishedAllLines?()
        }
    }

    func stop() {
        typingTask?.cancel()
    }
}
