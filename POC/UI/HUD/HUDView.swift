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
            
            switch world.model.hudStage {
            case .scanning:
                EmptyView()

            case .scanCompletePrompt:
                ScanDialogueBubbleView(
                    lines: [
                        "Scan the surrounding area first to start the game..."
                    ],
                    mascotName: "fly",
                    bubbleImageName: "long-bubble-card",
                    onFinishedAllLines: {
                        withAnimation {
                            world.model.hudStage = .transitioning
                        }
                    }
                )
                .transition(.opacity)

            case .transitioning:
                GIFImageView(name: "light-to-dark-transition")
                    .ignoresSafeArea()
                    .task {
                        // Estimate — adjust to the gif's real frame-count x delay
                        // if it should sync exactly with the animation's end.
                        try? await Task.sleep(for: .seconds(1.4))
                        withAnimation { world.model.hudStage = .mission }
                    }
                    .transition(.opacity)

            case .mission:
                EmptyView()
            }
            
            VStack {
                topBar

                Spacer()

                status
                
                if world.model.hudStage == .mission {
                    MissionChatBubbleView(
                        lines: ["I sense there are \(world.model.missionMangoTarget) mango here, let's find them."]
                    )
                    .padding(.bottom, 8)
                }
                
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
        .onChange(of: world.model.scanReady) { _, isReady in
            if isReady {
                withAnimation { world.model.hudStage = .scanCompletePrompt }
            }
        }
    }

    private var topBar: some View {
        HStack {
//            if world.model.hudStage != .mission {
//                // for debugging purposes — remove entirely once mission flow is verified
//                circleButton(
//                    icon: "chevron.left",
//                    size: 58,
//                    iconSize: 24,
//                    action: onBack
//                )
//            }

            if world.model.hudStage == .mission {
                MangoCounterView(
                    eatenCount: world.model.mangoEatenCount,
                    target: world.model.missionMangoTarget
                )
            }

            Spacer()
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
