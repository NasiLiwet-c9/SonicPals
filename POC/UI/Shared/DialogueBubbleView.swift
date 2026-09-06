//
//  DialogueBubbleView.swift
//  POC
//
//  Created by Asaryun on 15/08/26.
//

import Foundation
import SwiftUI

struct DialogueBubbleView: View {
    @State private var controller: DialogueViewModel
    @State private var popped = false

    let mascotName: String
    let mascotGIFName: String?
    let shortBubbleImageName: String
    let tallBubbleImageName: String
    let shortLineCharacterThreshold: Int
    let uiScale: CGFloat

    init(
        lines: [String],
        mascotName: String = "fly",
        mascotGIFName: String? = nil,
        shortBubbleImageName: String = "small-bubble-card",
        tallBubbleImageName: String = "tall-bubble-card",
        shortLineCharacterThreshold: Int = 24,
        loops: Bool = false,
        autoAdvance: Duration? = .milliseconds(3400),
        uiScale: CGFloat = 1,
        onFinishedAllLines: (() -> Void)? = nil
    ) {
        _controller = State(
            wrappedValue: DialogueViewModel(
                lines: lines,
                loops: loops,
                autoAdvance: autoAdvance,
                onFinishedAllLines: onFinishedAllLines
            )
        )

        self.mascotName = mascotName
        self.mascotGIFName = mascotGIFName
        self.shortBubbleImageName = shortBubbleImageName
        self.tallBubbleImageName = tallBubbleImageName
        self.shortLineCharacterThreshold = shortLineCharacterThreshold
        self.uiScale = uiScale
    }

    private var isCurrentLineShort: Bool {
        guard controller.lines.indices.contains(controller.currentLineIndex) else {
            return true
        }

        return controller.lines[controller.currentLineIndex].count <= shortLineCharacterThreshold
    }

    private var bubbleImageName: String {
        isCurrentLineShort
            ? shortBubbleImageName
            : tallBubbleImageName
    }

    var body: some View {
        HStack(
            alignment: .top,
            spacing: UICfg.Dlg.gap * uiScale
        ) {
            bubble
                .offset(
                    y: (
                        isCurrentLineShort
                            ? UICfg.Dlg.shortY
                            : UICfg.Dlg.tallY
                    ) * uiScale
                )

            mascot
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

    @ViewBuilder
    private var mascot: some View {
        if let mascotGIFName {
            GIFImageView(name: mascotGIFName)
                .frame(
                    width: UICfg.Dlg.bat * uiScale,
                    height: UICfg.Dlg.bat * uiScale
                )
        } else {
            AssetImageView(name: mascotName)
                .frame(
                    width: UICfg.Dlg.bat * uiScale,
                    height: UICfg.Dlg.bat * uiScale
                )
        }
    }

    private var bubble: some View {
        ZStack {
            Image(bubbleImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)

            Text(controller.visibleText)
                .font(
                    .system(
                        size: UICfg.Dlg.txt * uiScale,
                        weight: .bold
                    )
                )
                .multilineTextAlignment(.center)
                .lineLimit(isCurrentLineShort ? 1 : 4)
                .minimumScaleFactor(0.75)
                .foregroundStyle(.black)
                .padding(
                    .horizontal,
                    UICfg.Dlg.padX * uiScale
                )
                .offset(
                    y: -UICfg.Bubble.textLift(
                        width: UICfg.Dlg.bubW * uiScale
                    )
                )
        }
        .frame(
            width: UICfg.Dlg.bubW * uiScale,
            height: (
                isCurrentLineShort
                    ? UICfg.Dlg.shortH
                    : UICfg.Dlg.tallH
            ) * uiScale
        )
        // Each new line pops in, replacing the old typewriter reveal.
        .scaleEffect(popped ? 1 : 0.86)
        .opacity(popped ? 1 : 0)
        .task(id: controller.currentLineIndex) {
            popped = false

            withAnimation(
                .spring(response: 0.32, dampingFraction: 0.64)
            ) {
                popped = true
            }
        }
    }
}
