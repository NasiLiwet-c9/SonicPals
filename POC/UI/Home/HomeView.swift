//
//  HomeView.swift
//  POC
//
//  Created by Asaryun on 13/08/26.
//

import SwiftUI

struct HomeView: View {
    var mascotName = "fly"

    var dialogueLines: [String] = [
        "Hi.... i'm Battiw",
        "I'm hungry, help me find something to eat tonight...!"
    ]

    var primaryButtonText = "Fly and Find!"
    var onStart: () -> Void = {}
    var onSelectMode: () -> Void = {}

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background(
                    width: geo.size.width,
                    height: geo.size.height
                )

                VStack {
                    Spacer()

                    DialogueBubbleView(
                        lines: dialogueLines,
                        mascotName: mascotName,
                        mascotGIFName: "flying-animation-mascot",
                        loops: true
                    )

                    VStack(spacing: 18) {
                        Button(action: onStart) {
                            ZStack {
                                Image("filled-button-border")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)

                                Text(primaryButtonText.uppercased())
                                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.black)
                            }
                            .frame(width: 220, height: 64)
                        }
                        .buttonStyle(.plain)

                        Button(action: onSelectMode) {
                            Image("map-btn-yellow")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 76, height: 86)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open map")
                    }
                    .padding(.bottom, 210)
                }
                .padding(.horizontal, 20)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.light)
    }

    private func background(
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        GIFImageView(
            name: "bg-main-animation",
            contentMode: .scaleAspectFill
        )
        .frame(
            width: width,
            height: height
        )
        .clipped()
        .allowsHitTesting(false)
    }
}

#Preview {
    HomeView()
}
