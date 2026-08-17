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
            wrappedValue: DialogueViewModel(
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
                    .offset(y: isCurrentLineShort ? -15 : -88)
            
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
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .lineLimit(isCurrentLineShort ? 1 : 4)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.bottom, isCurrentLineShort ? 18 : 20)
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
