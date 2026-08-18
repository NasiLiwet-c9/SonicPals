//
//  MissionChatBubbleView.swift
//  POC
//
//  Created by Asaryun on 17/08/26.
//

import Foundation
import SwiftUI
struct MissionChatBubbleView: View {
    @StateObject private var viewModel: DialogueViewModel

    let rightBubbleImageName: String
    let leftBubbleImageName: String

    init(
        lines: [String],
        typingSpeed: Double = 0.03,
        rightBubbleImageName: String = "long-bubble-card",
        leftBubbleImageName: String = "long-bubble-card-left",
        onFinishedAllLines: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: DialogueViewModel(
                lines: lines,
                typingSpeed: typingSpeed,
                onFinishedAllLines: onFinishedAllLines
            )
        )
        self.rightBubbleImageName = rightBubbleImageName
        self.leftBubbleImageName = leftBubbleImageName
    }

    private var isEvenLine: Bool {
        viewModel.currentLineIndex.isMultiple(of: 2)
    }

    var body: some View {
        HStack {
            if isEvenLine {
                Spacer(minLength: 0)
                bubble(imageName: rightBubbleImageName)
            } else {
                bubble(imageName: leftBubbleImageName)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.advance() }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private func bubble(imageName: String) -> some View {
        ZStack {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)

            Text(viewModel.visibleText)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .foregroundStyle(.black)
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        // long-bubble-card's real pixel ratio is 232x100.
        .frame(width: 230, height: 230 * 100 / 232)
    }
}
