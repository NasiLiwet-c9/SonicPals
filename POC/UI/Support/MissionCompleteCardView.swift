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
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                Color.black
                    .opacity(show ? UICfg.Done.dim : 0)
                    .ignoresSafeArea()

                if confetti {
                    ConfettiBurstView()
                        .allowsHitTesting(false)
                }

                ZStack(alignment: .bottomLeading) {
                    GIFImageView(
                        name: "mission-completed-animation",
                        contentMode: .scaleAspectFit
                    )
                    .frame(
                        width: UICfg.v(UICfg.Done.cardW, size)
                    )
                    .offset(
                        y: UICfg.y(UICfg.Done.cardY, size)
                    )

                    Button {
                        sfx.tap()
                        onNext()
                    } label: {
                        ZStack {
                            Image("btn-sort")
                                .resizable()
                                .aspectRatio(
                                    144.0 / 57.0,
                                    contentMode: .fit
                                )
                                .frame(
                                    width: UICfg.v(
                                        UICfg.Done.nextW,
                                        size
                                    )
                                )

                            Text("Next")
                                .font(
                                    .system(
                                        size: UICfg.v(20, size),
                                        weight: .heavy,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(.black)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(
                        .leading,
                        UICfg.x(UICfg.Done.nextX, size)
                    )
                    .padding(
                        .bottom,
                        UICfg.y(UICfg.Done.nextY, size)
                    )
                }
                .padding(
                    .bottom,
                    UICfg.y(UICfg.Done.bottom, size)
                )
                .scaleEffect(show ? 1 : 0.72)
                .opacity(show ? 1 : 0)
            }
            .frame(
                width: size.width,
                height: size.height
            )
        }
        .ignoresSafeArea()
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
        GeometryReader { geo in
            ZStack {
                ForEach(0..<30, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colors[i % colors.count])
                        .frame(
                            width: i.isMultiple(of: 3) ? 8 : 6,
                            height: i.isMultiple(of: 2) ? 14 : 10
                        )
                        .position(
                            x: geo.size.width * 0.5,
                            y: geo.size.height * 0.43
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
