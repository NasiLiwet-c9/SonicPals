//
//  MissionCompleteCardView.swift
//  POC
//
//  Created by Asaryun on 18/08/26.
//

import SwiftUI

struct MissionCompleteCardView: View {
    let onNext: () -> Void

    @State private var show = false
    @State private var confetti = false

    private let sfx = SfxSvc.shared

    var body: some View {
        ZStack {
            Color.black.opacity(show ? 0.55 : 0)
                .ignoresSafeArea()

            if confetti {
                ConfettiBurstView()
                    .allowsHitTesting(false)
            }

            ZStack(alignment: .bottomLeading) {
                GIFImageView(name: "mission-completed-animation")
                    .aspectRatio(1806.0 / 1537.0, contentMode: .fit)
                    .scaleEffect(1.3)

                Button(action: onNext) {
                    ZStack {
                        Image("btn-sort")
                            .resizable()
                            .aspectRatio(144.0 / 57.0, contentMode: .fit)
                            .frame(width: 130)

                        Text("Next")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.black)
                    }
                }
                .buttonStyle(.plain)
                .padding(.leading, 38)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60)
            .scaleEffect(show ? 1 : 0.72)
            .opacity(show ? 1 : 0)
        }
        .onAppear {
            sfx.levelDone()
            sfx.popup()

            confetti = true

            withAnimation(
                .spring(
                    response: 0.48,
                    dampingFraction: 0.72
                )
            ) {
                show = true
            }
        }
    }
}

private struct ConfettiBurstView: View {
    @State private var go = false

    private let colors: [Color] = [
        .yellow,
        .orange,
        .pink,
        .cyan,
        .green,
        .purple
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<30, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colors[i % colors.count])
                        .frame(
                            width: i.isMultiple(of: 3) ? 8 : 6,
                            height: i.isMultiple(of: 2) ? 14 : 10
                        )
                        .position(
                            x: proxy.size.width * 0.5,
                            y: proxy.size.height * 0.43
                        )
                        .offset(
                            x: go ? xOffset(i) : 0,
                            y: go ? yOffset(i) : 0
                        )
                        .rotationEffect(
                            .degrees(
                                go
                                    ? Double(i * 61 + 180)
                                    : 0
                            )
                        )
                        .opacity(go ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.25)
                                .delay(
                                    Double(i % 6) * 0.025
                                ),
                            value: go
                        )
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    go = true
                }
            }
        }
        .ignoresSafeArea()
    }

    private func xOffset(_ i: Int) -> CGFloat {
        CGFloat(((i * 53) % 300) - 150)
    }

    private func yOffset(_ i: Int) -> CGFloat {
        CGFloat(((i * 79) % 320) - 190)
    }
}
