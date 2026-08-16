//
//  DialogueBubbleView.swift
//  POC
//
//  Created by Asaryun on 15/08/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class DialogueController: ObservableObject {
    @Published private(set) var visibleText: String = ""
    @Published private(set) var isLineFullyTyped = false
    @Published private(set) var currentLineIndex = 0

    let lines: [String]
    var typingSpeed: Double
    var onFinishedAllLines: (() -> Void)?

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

    /// Call this from a tap gesture on the bubble.
    func advance() {
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

struct DialogueBubbleView: View {
    @StateObject private var controller: DialogueController
    let mascotName: String
    let shortBubbleImageName: String
    let tallBubbleImageName: String
    let shortLineCharacterThreshold: Int
    
    init(
        lines: [String],
        typingSpeed: Double = 0.03,
        mascotName: String = "fly",
        shortBubbleImageName: String = "small-bubble-card",
        tallBubbleImageName: String = "tall-bubble-card",
        shortLineCharacterThreshold: Int = 24,
        onFinishedAllLines: (() -> Void)? = nil
    ) {
        _controller = StateObject(
            wrappedValue: DialogueController(
                lines: lines,
                typingSpeed: typingSpeed,
                onFinishedAllLines: onFinishedAllLines
            )
        )
        self.mascotName = mascotName
        self.shortBubbleImageName = shortBubbleImageName
        self.tallBubbleImageName = tallBubbleImageName
        self.shortLineCharacterThreshold = shortLineCharacterThreshold
    }
    
    // Picks the asset by content length instead of stretching one image.
    private var isCurrentLineShort: Bool {
        guard controller.lines.indices.contains(controller.currentLineIndex) else { return true }
        return controller.lines[controller.currentLineIndex].count <= shortLineCharacterThreshold
    }
    
    private var bubbleImageName: String {
        isCurrentLineShort ? shortBubbleImageName : tallBubbleImageName
    }
    
    var body: some View {
            HStack(alignment: .top, spacing: isCurrentLineShort ? -50 : -50) {
                bubble
                    .offset(y: isCurrentLineShort ? -15 : -90)
            
                Model3DView(name: mascotName)
                    .frame(width: 240, height: 240)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                controller.advance()
            }
            .onAppear {
                controller.start()
            }
            .onDisappear {
                controller.stop()
            }
        }

        private var bubble: some View {
            ZStack {
                Image(bubbleImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                Text(controller.visibleText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .lineLimit(isCurrentLineShort ? 1 : 3)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.bottom, isCurrentLineShort ? 12 : 20)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            // Same fix as before — explicit height computed from each PNG's
            // real aspect ratio (163x78 small, 163x136 tall), not left implicit.
            .frame(
                width: isCurrentLineShort ? 170 : 170,
                height: isCurrentLineShort ? 170 * 78 / 163 : 200 * 136 / 163
            )
        }
    
    private var bubbleOffset: CGSize {
        isCurrentLineShort
        ? CGSize(width: -75, height: -140)
        : CGSize(width: -90, height: -160)
    }
}
