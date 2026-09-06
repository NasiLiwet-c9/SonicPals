//
//  CoachBubble.swift
//  POC
//
//  Created by Shan Newcastle on 04/09/26.
//

import SwiftUI

/// Battiw teaching, over the live camera. One short line at a time.
struct CoachBubble: View {
    let line: String
    let lineID: Int
    let uiScale: CGFloat

    @State private var popped = false

    var body: some View {
        HStack(alignment: .top, spacing: UICfg.Sess.topGap * uiScale) {
            bubble

            AssetImageView(name: "fly")
                .frame(
                    width: UICfg.Sess.topBat * uiScale,
                    height: UICfg.Sess.topBat * uiScale
                )
                .offset(
                    x: UICfg.Sess.topBatX * uiScale,
                    y: UICfg.Sess.topBatY * uiScale
                )
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .scaleEffect(popped ? 1 : 0.86)
        .opacity(popped ? 1 : 0)
        .allowsHitTesting(false)
        .task(id: lineID) {
            popped = false

            withAnimation(.spring(response: 0.32, dampingFraction: 0.64)) {
                popped = true
            }
        }
    }

    private var bubble: some View {
        ZStack {
            Image("long-bubble-card")
                .resizable()
                .aspectRatio(contentMode: .fit)

            Text(line)
                .font(
                    .system(
                        size: UICfg.Sess.topTxt * uiScale,
                        weight: .heavy
                    )
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .foregroundStyle(.black)
                .padding(.leading, UICfg.Sess.topPadX * uiScale)
                .padding(.trailing, UICfg.Sess.topPadMascot * uiScale)
                .offset(
                    y: -UICfg.Bubble.textLift(
                        width: UICfg.Sess.topW * uiScale
                    )
                )
        }
        .frame(width: UICfg.Sess.topW * uiScale)
    }
}
