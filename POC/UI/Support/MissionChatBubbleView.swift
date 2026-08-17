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

    let avatarName: String
    let bubbleImageName: String

    init(
        lines: [String],
        typingSpeed: Double = 0.03,
        avatarName: String = "happybattiw-with-eyeglass",
        bubbleImageName: String = "long-bubble-card",
        onFinishedAllLines: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: DialogueViewModel(
                lines: lines,
                typingSpeed: typingSpeed,
                onFinishedAllLines: onFinishedAllLines
            )
        )

        self.avatarName = avatarName
        self.bubbleImageName = bubbleImageName
    }

    var body: some View {
        HStack {
            if viewModel.currentLineIndex.isMultiple(of: 2) {
                // FIRST LINE → RIGHT
                Spacer(minLength: 0)

                dialogueGroup
            } else {
                // SECOND LINE → LEFT
                dialogueGroup

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.advance()
        }
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    private var dialogueGroup: some View {
        VStack(spacing: -4) {
            bubble
        }
    }

    private var bubble: some View {
        ZStack {
            Image(bubbleImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)

            Text(viewModel.visibleText)
                .font(
                    .system(
                        size: 13,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .foregroundStyle(.black)
                .padding(.horizontal, 17)
                .padding(.bottom, 16)
                .frame(
                    maxWidth: .infinity,
                    alignment: .topLeading
                )
        }
        .frame(
            width: 190,
            height: 82
        )
    }
}
