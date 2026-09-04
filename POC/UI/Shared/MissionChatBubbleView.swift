//
//  MissionChatBubbleView.swift
//  POC
//
//  Created by Asaryun on 17/08/26.
//

import SwiftUI

/// Battiw's line during the hunt. Deliberately dumb — `MissionSvc` owns
/// the queue and the pacing, so this only draws the current line.
struct MissionChatBubbleView: View {
    let text: String
    let lineID: Int
    let uiScale: CGFloat

    var bubbleImageName = "long-bubble-card"

    @State private var popped = false

    var body: some View {
        HStack {
            Spacer(minLength: 0)

            bubble
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var bubble: some View {
        ZStack {
            Image(bubbleImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)

            Text(text)
                .font(
                    .system(
                        size: UICfg.Sess.botTxt * uiScale,
                        weight: .bold
                    )
                )
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.black)
                .padding(.horizontal, UICfg.Sess.botPadX * uiScale)
                .padding(.bottom, UICfg.Sess.botPadY * uiScale)
        }
        .frame(width: UICfg.Sess.botW * uiScale)
        .scaleEffect(popped ? 1 : 0.82)
        .opacity(popped ? 1 : 0)
        .task(id: lineID) {
            popped = false

            withAnimation(
                .spring(response: 0.34, dampingFraction: 0.62)
            ) {
                popped = true
            }
        }
    }
}
