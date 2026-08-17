//
//  ScanDialogueBubbleView.swift
//  POC
//
//  Scan prompt shown after the room scan is completed.
//

import SwiftUI

struct ScanDialogueBubbleView: View {
    @StateObject private var controller: DialogueViewModel

    let mascotName: String
    let bubbleImageName: String

    init(
        lines: [String],
        typingSpeed: Double = 0.03,
        mascotName: String = "fly",
        bubbleImageName: String = "long-bubble-card",
        onFinishedAllLines: (() -> Void)? = nil
    ) {
        _controller = StateObject(
            wrappedValue: DialogueViewModel(
                lines: lines,
                typingSpeed: typingSpeed,
                onFinishedAllLines: onFinishedAllLines
            )
        )

        self.mascotName = mascotName
        self.bubbleImageName = bubbleImageName
    }

    var body: some View {
        VStack {
            HStack(
                alignment: .top,
                spacing: -8
            ) {
                bubble

                Model3DView(name: mascotName)
                    .frame(
                        width: 110,
                        height: 110
                    )
                    .offset(
                        x: -12,
                        y: 38
                    )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .center
            )

            Spacer()
        }
        .padding(.top, 70)
        .padding(.horizontal, 24)
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
                        size: 13,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .multilineTextAlignment(.leading)
                .foregroundStyle(.black)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 18)
                .padding(.bottom, 14)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
        }
        .frame(
            width: 210,
            height: 91
        )
    }
}