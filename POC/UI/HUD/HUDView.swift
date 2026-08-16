//
//  HUDView.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//  Updated by Asaryun on 13/08/26

import SwiftUI

struct HUDView: View {
    let world: ECSWorld

    let onBack: () -> Void
    let onInfo: () -> Void

    var body: some View {
        ZStack {
            reticle

            VStack {
                topBar

                Spacer()

                status

                controls
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        //debug
//        .onAppear {
//            print("ping-btn found:", UIImage(named: "ping-btn") != nil)
//            print("eat-btn found:", UIImage(named: "eat-btn") != nil)
//        }
    }

    private var topBar: some View {
        HStack {
            
            // for debugging purposes
            circleButton(
                icon: "chevron.left",
                size: 58,
                iconSize: 24,
                action: onBack
            )

            Spacer()

//            circleButton(
//                icon: "info",
//                size: 58,
//                iconSize: 24,
//                action: onInfo
//            )
//            circleButton(
//                icon:
//                    world.model.dimOn
//                    ? "moon.stars.fill"
//                    : "sun.max.fill",
//                size: 64,
//                iconSize: 25
//            ) {
//                world.perform(.toggleDim)
//            }.glassEffect()
        }
    }

    @ViewBuilder
    private var status: some View {
        if !world.model.msg.isEmpty {
            Text(world.model.msg)
                .font(.caption)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    .ultraThinMaterial,
                    in: Capsule()
                )
                .padding(.bottom, 12)
        }
    }

    private var controls: some View {
        HStack(
            alignment: .bottom,
            spacing: 36
        ) {
//            circleButton(
//                icon:
//                    world.model.dimOn
//                    ? "lightbulb.fill"
//                    : "lightbulb",
//                size: 68,
//                iconSize: 25
//            ) {
//                world.perform(.toggleDim)
//            }

            if world.model.mangoEatReady {
                eatButton
                    .transition(.scale.combined(with: .opacity))
            } else {
                waveButton
                    .transition(.scale.combined(with: .opacity))
            }

            //for debugging purposes
            circleButton(
                icon: "tree",
                size: 68,
                iconSize: 27
            ) {
                world.perform(.spawnTarget)
            }.glassEffect()
            .disabled(
                !world.model.canSpawn
            )
            .opacity(
                world.model.canSpawn
                ? 1
                : 0.4
            )
        }
        .animation(
            .easeInOut(duration: 0.2),
            value: world.model.mangoEatReady
        )
    }

    private var waveButton: some View {
        Button {
            world.perform(.sendWave)
        } label: {
            Image("ping-btn")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 108, height: 108)
        }
        .buttonStyle(.plain)
        .disabled(!world.model.canWave)
        .opacity(world.model.canWave ? 1 : 0.4)
        .accessibilityLabel("Send ultrasonic wave")
    }

    private var eatButton: some View {
        Button {
            world.perform(.eatMango)
        } label: {
            Image("eat-btn")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 108, height: 108)
        }
        .buttonStyle(.plain)
        .glassEffect()
        .accessibilityLabel("Eat mango")
    }
    
    private var reticle: some View {
        ZStack {
            Circle()
                .stroke(
                    .white.opacity(0.45),
                    lineWidth: 1
                )
                .frame(
                    width: 82,
                    height: 82
                )

            Circle()
                .stroke(
                    .white.opacity(0.35),
                    lineWidth: 1
                )
                .frame(
                    width: 40,
                    height: 40
                )

            Rectangle()
                .fill(
                    .white.opacity(0.45)
                )
                .frame(
                    width: 1,
                    height: 94
                )

            Rectangle()
                .fill(
                    .white.opacity(0.45)
                )
                .frame(
                    width: 94,
                    height: 1
                )

            Circle()
                .fill(
                    .white.opacity(0.8)
                )
                .frame(
                    width: 5,
                    height: 5
                )
        }
        .allowsHitTesting(false)
    }

    private func circleButton(
        icon: String,
        size: CGFloat,
        iconSize: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(
                systemName: icon
            )
            .font(
                .system(
                    size: iconSize,
                    weight: .medium
                )
            )
            .foregroundStyle(.primary)
            .frame(
                width: size,
                height: size
            )
            .background(
                .ultraThinMaterial,
                in: Circle()
            )
            .overlay {
                Circle()
                    .stroke(
                        .primary.opacity(0.15),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}
