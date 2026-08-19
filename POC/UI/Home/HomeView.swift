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
            let size = geo.size

            ZStack {
                Color(red: 0.13, green: 0.11, blue: 0.28)
                    .ignoresSafeArea()

                background(size)

                VStack {
                    Spacer()

                    DialogueBubbleView(
                        lines: dialogueLines,
                        mascotName: mascotName,
                        mascotGIFName: "flying-animation-mascot",
                        loops: true,
                        uiScale: UICfg.s(size)
                    )

                    VStack(spacing: UICfg.v(UICfg.Home.gap, size)) {
                        Button(action: onStart) {
                            ZStack {
                                Image("filled-button-border")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)

                                Text(primaryButtonText.uppercased())
                                    .font(
                                        .system(
                                            size: UICfg.v(20, size),
                                            weight: .heavy,
                                            design: .rounded
                                        )
                                    )
                                    .foregroundStyle(.black)
                            }
                            .frame(
                                width: UICfg.v(UICfg.Home.playW, size),
                                height: UICfg.v(UICfg.Home.playH, size)
                            )
                        }
                        .buttonStyle(.plain)

                        Button(action: onSelectMode) {
                            Image("map-btn-yellow")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(
                                    width: UICfg.v(UICfg.Home.mapW, size),
                                    height: UICfg.v(UICfg.Home.mapH, size)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open map")
                    }
                    .padding(
                        .bottom,
                        UICfg.v(UICfg.Home.bottom, size)
                    )
                }
                .padding(
                    .horizontal,
                    UICfg.v(20, size)
                )
            }
            .frame(
                width: size.width,
                height: size.height
            )
        }
        .ignoresSafeArea()
        .preferredColorScheme(.light)
    }

    private func background(_ size: CGSize) -> some View {
        let bgW = UICfg.v(UICfg.Home.bgW, size)
        let bgH = bgW * (1748.0 / 804.0)

        return GIFImageView(
            name: "bg-main-animation",
            contentMode: .scaleAspectFit
        )
        .frame(
            width: bgW,
            height: bgH
        )
        .offset(
            y: UICfg.y(UICfg.Home.bgY, size)
        )
        .allowsHitTesting(false)
    }
}

#Preview {
    HomeView()
}
