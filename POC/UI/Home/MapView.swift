//
//  MapView.swift
//  POC
//
//  Created by Shan Newcastle on 19/08/26.
//

import SwiftUI

struct MapView: View {
    let onBack: () -> Void

    @State private var lockMsg = false

    private let sfx = SfxSvc.shared

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            let bgW = UICfg.v(
                UICfg.Map.bgW,
                size
            )

            let bgH = UICfg.v(
                UICfg.Map.bgH,
                size
            )

            let sx = bgW / UICfg.refW
            let sy = bgH / UICfg.refH
            let sc = min(sx, sy)

            ZStack {
                Color(
                    red: 0.08,
                    green: 0.07,
                    blue: 0.18
                )
                .ignoresSafeArea()

                ZStack {
                    GIFImageView(
                        name: "bg-map-animation",
                        contentMode: .scaleAspectFit
                    )
                    .frame(
                        width: bgW,
                        height: bgH
                    )
                    .allowsHitTesting(false)

                    GIFImageView(
                        name: "flying-animation-mascot"
                    )
                    .frame(
                        width: UICfg.Map.bat * sc,
                        height: UICfg.Map.bat * sc
                    )
                    .position(
                        x: UICfg.Map.batX * sx,
                        y: UICfg.Map.batY * sy
                    )
                    .allowsHitTesting(false)

                    levelOneButton(
                        sx: sx,
                        sy: sy
                    )

                    lockButton(
                        sx: sx,
                        sy: sy
                    )

                    if lockMsg {
                        lockBubble(scale: sc)
                            .position(
                                x: UICfg.Map.msgX * sx,
                                y: UICfg.Map.msgY * sy
                            )
                            .transition(
                                .scale(scale: 0.75)
                                .combined(with: .opacity)
                            )
                            .zIndex(5)
                    }
                }
                .frame(
                    width: bgW,
                    height: bgH
                )
                .offset(
                    y: UICfg.y(
                        UICfg.Map.bgY,
                        size
                    )
                )

                Button {
                    sfx.tap()
                    onBack()
                } label: {
                    Image("arrow-left")
                        .resizable()
                        .aspectRatio(
                            contentMode: .fit
                        )
                        .frame(
                            width: UICfg.v(
                                UICfg.Map.backW,
                                size
                            ),
                            height: UICfg.v(
                                UICfg.Map.backH,
                                size
                            )
                        )
                }
                .buttonStyle(.plain)
                .position(
                    x: UICfg.x(
                        UICfg.Map.backX,
                        size
                    ),
                    y: UICfg.y(
                        UICfg.Map.backY,
                        size
                    )
                )
                .accessibilityLabel("Back")
            }
            .frame(
                width: size.width,
                height: size.height
            )
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private func levelOneButton(
        sx: CGFloat,
        sy: CGFloat
    ) -> some View {
        Button {
            sfx.tap()
            onBack()
        } label: {
            Rectangle()
                .fill(
                    Color.white.opacity(0.001)
                )
                .frame(
                    width: UICfg.Map.oneW * sx,
                    height: UICfg.Map.oneH * sy
                )
        }
        .buttonStyle(.plain)
        .position(
            x: UICfg.Map.oneX * sx,
            y: UICfg.Map.oneY * sy
        )
        .accessibilityLabel("Level 1")
    }

    private func lockButton(
        sx: CGFloat,
        sy: CGFloat
    ) -> some View {
        Button {
            sfx.tap()

            if !lockMsg {
                sfx.dialogue()
            }

            withAnimation(
                .spring(
                    response: 0.38,
                    dampingFraction: 0.72
                )
            ) {
                lockMsg.toggle()
            }
        } label: {
            Rectangle()
                .fill(
                    Color.white.opacity(0.001)
                )
                .frame(
                    width: UICfg.Map.lockW * sx,
                    height: UICfg.Map.lockH * sy
                )
        }
        .buttonStyle(.plain)
        .position(
            x: UICfg.Map.lockX * sx,
            y: UICfg.Map.lockY * sy
        )
        .accessibilityLabel("Locked level")
    }

    private func lockBubble(
        scale: CGFloat
    ) -> some View {
        let w = UICfg.Map.msgW * scale
        let h = w * (100.0 / 232.0)

        return ZStack {
            Image("long-bubble-card")
                .resizable()
                .aspectRatio(
                    contentMode: .fit
                )

            Text(
                "Whelson will be\navailable soon"
            )
            .font(
                .system(
                    size: UICfg.Map.msgTxt * scale,
                    weight: .semibold,
                    design: .rounded
                )
            )
            .multilineTextAlignment(.center)
            .foregroundStyle(.black)
            .padding(
                .horizontal,
                20 * scale
            )
            .offset(
                y: UICfg.Map.msgTxtY * scale
            )
        }
        .frame(
            width: w,
            height: h
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(
                .easeInOut(duration: 0.18)
            ) {
                lockMsg = false
            }
        }
    }
}

#Preview("Map") {
    MapView {}
}
