//
//  ScanDialogueBubbleView.swift
//  POC
//
//  Created by Asaryun on 17/08/26.
//

import SwiftUI

struct ScanDialogueBubbleView: View {
    @State private var controller: DialogueViewModel
    @State private var popped = false

    let mascotName: String
    let bubbleImageName: String
    let uiScale: CGFloat

    init(
        lines: [String],
        mascotName: String = "fly",
        bubbleImageName: String = "long-bubble-card",
        uiScale: CGFloat = 1,
        autoAdvance: Duration? = .seconds(3.2),
        onFinishedAllLines: (() -> Void)? = nil
    ) {
        _controller = State(
            wrappedValue: DialogueViewModel(
                lines: lines,
                autoAdvance: autoAdvance,
                onFinishedAllLines: onFinishedAllLines
            )
        )

        self.mascotName = mascotName
        self.bubbleImageName = bubbleImageName
        self.uiScale = uiScale
    }

    var body: some View {
        VStack {
            HStack(
                alignment: .top,
                spacing: UICfg.Sess.topGap * uiScale
            ) {
                bubble

                AssetImageView(name: mascotName)
                    .frame(
                        width: UICfg.Sess.topBat * uiScale,
                        height: UICfg.Sess.topBat * uiScale
                    )
                    .offset(
                        x: UICfg.Sess.topBatX * uiScale,
                        y: UICfg.Sess.topBatY * uiScale
                    )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .center
            )

            Spacer()
        }
        .padding(
            .top,
            10 * uiScale
        )
        .padding(
            .horizontal,
            24 * uiScale
        )
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
                .aspectRatio(
                    contentMode: .fit
                )

            Text(controller.visibleText)
                .font(
                    .system(
                        size: UICfg.Sess.topTxt * uiScale,
                        weight: .bold
                    )
                )
                .multilineTextAlignment(.leading)
                .foregroundStyle(.black)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .padding(
                    .horizontal,
                    UICfg.Sess.topPadX * uiScale
                )
                .padding(
                    .top,
                    UICfg.Sess.topPadY * uiScale
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
        }
        .frame(
            width: UICfg.Sess.topW * uiScale,
            height: UICfg.Sess.topH * uiScale
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
