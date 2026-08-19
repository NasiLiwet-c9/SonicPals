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
    let uiScale: CGFloat

    init(
        lines: [String],
        typingSpeed: Double = 0.03,
        rightBubbleImageName: String = "long-bubble-card",
        leftBubbleImageName: String = "long-bubble-card-left",
        uiScale: CGFloat = 1,
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
        self.uiScale = uiScale
    }

    private var isEvenLine: Bool {
        viewModel.currentLineIndex.isMultiple(of: 2)
    }

    var body: some View {
        HStack {
            if isEvenLine {
                Spacer(minLength: 0)

                bubble(
                    imageName: rightBubbleImageName
                )
            } else {
                bubble(
                    imageName: leftBubbleImageName
                )

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

    private func bubble(
        imageName: String
    ) -> some View {
        let width = UICfg.Sess.botW * uiScale

        return ZStack {
            Image(imageName)
                .resizable()
                .aspectRatio(
                    contentMode: .fit
                )

            Text(viewModel.visibleText)
                .font(
                    .system(
                        size: UICfg.Sess.botTxt * uiScale,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .foregroundStyle(.black)
                .padding(
                    .horizontal,
                    UICfg.Sess.botPadX * uiScale
                )
                .padding(
                    .bottom,
                    UICfg.Sess.botPadY * uiScale
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .topLeading
                )
        }
        .frame(
            width: width,
            height: width * 100 / 232
        )
    }
}
