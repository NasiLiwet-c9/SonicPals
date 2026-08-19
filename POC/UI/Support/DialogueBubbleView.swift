//
//  DialogueBubbleView.swift
//  POC
//
//  Created by Asaryun on 15/08/26.
//

import Foundation
import SwiftUI
import Combine

struct DialogueBubbleView: View {
    @StateObject private var controller: DialogueViewModel

    let mascotName: String
    let mascotGIFName: String?
    let shortBubbleImageName: String
    let tallBubbleImageName: String
    let shortLineCharacterThreshold: Int
    let uiScale: CGFloat

    init(
        lines: [String],
        typingSpeed: Double = 0.03,
        mascotName: String = "fly",
        mascotGIFName: String? = nil,
        shortBubbleImageName: String = "small-bubble-card",
        tallBubbleImageName: String = "tall-bubble-card",
        shortLineCharacterThreshold: Int = 24,
        loops: Bool = false,
        uiScale: CGFloat = 1,
        onFinishedAllLines: (() -> Void)? = nil
    ) {
        _controller = StateObject(
            wrappedValue: DialogueViewModel(
                lines: lines,
                typingSpeed: typingSpeed,
                loops: loops,
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
            Model3DView(name: mascotName)
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
                        weight: .bold,
                        design: .rounded
                    )
                )
                .multilineTextAlignment(.leading)
                .lineLimit(isCurrentLineShort ? 1 : 4)
                .minimumScaleFactor(0.75)
                .foregroundStyle(.black)
                .padding(
                    .horizontal,
                    UICfg.Dlg.padX * uiScale
                )
                .padding(
                    .bottom,
                    (isCurrentLineShort ? 18 : 20) * uiScale
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .topLeading
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
    }
}
