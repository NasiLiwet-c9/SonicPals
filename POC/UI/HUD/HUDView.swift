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

    @State private var scanIntroDone = false

    private let sfx = SfxSvc.shared

    var body: some View {
        ZStack {
            reticle

//            #if DEBUG
//            Button("SKIP TO COMPLETION") {
//                world.model.missionComplete = true
//                world.model.showMissionCompleteCard = true
//                world.model.missionDialogueVisible = false
//            }
//            .buttonStyle(.borderedProminent)
//            .position(x: 120, y: 100)
//            .zIndex(100)
//            #endif

            if world.model.quizTransitionID > 0,
               !world.model.showQuiz {
                GIFImageView(name: "dark-to-light-transition")
                    .ignoresSafeArea()
                    .id(world.model.quizTransitionID)
                    .zIndex(15)
                    .allowsHitTesting(false)
                    .task(id: world.model.quizTransitionID) {
                        try? await Task.sleep(for: .milliseconds(700))

                        withAnimation(.easeInOut(duration: 0.2)) {
                            world.model.showQuiz = true
                        }
                    }
            }

            if world.model.showMissionCompleteCard {
                MissionCompleteCardView {
                    startQuizTransition()
                }
                .transition(.opacity)
                .zIndex(10)
            }

            if world.model.showQuiz {
                QuestionCardView(
                    onPlayAgain: {
                        sfx.tap()
                        restartMission()
                    },
                    onBackToMenu: {
                        sfx.tap()
                        onBack()
                    }
                )
                .id(world.model.quizTransitionID)
                .transition(.opacity)
                .zIndex(20)
            }

            if world.model.eatAnimationVisible {
                GIFImageView(name: "eat-animation")
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .id(world.model.eatAnimationID)
                    .allowsHitTesting(false)
                    .task(id: world.model.eatAnimationID) {
                        try? await Task.sleep(for: .milliseconds(500))
                        world.model.eatAnimationVisible = false
                    }
                    .transition(.opacity)
            }

            switch world.model.hudStage {
            case .scanning:
                if !scanIntroDone {
                    ScanDialogueBubbleView(
                        lines: [
                            "Scan the surrounding area first to start the game..."
                        ],
                        mascotName: "fly",
                        bubbleImageName: "long-bubble-card",
                        onFinishedAllLines: {
                            withAnimation {
                                scanIntroDone = true
                            }
                        }
                    )
                    .transition(.opacity)
                }

            case .scanCompletePrompt:
                Color.clear
                    .task {
                        world.endScan()
                        world.model.missionDark = false

                        try? await Task.sleep(for: .milliseconds(180))

                        withAnimation {
                            world.model.hudStage = .transitioning
                        }
                    }

            case .transitioning:
                ZStack {
                    GIFImageView(name: "light-to-dark-transition")
                        .ignoresSafeArea()

                    Color.black
                        .opacity(world.model.missionDark ? 0.18 : 0)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
                .task {
                    world.model.missionDark = false

                    try? await Task.sleep(for: .milliseconds(700))

                    withAnimation(.easeInOut(duration: 0.35)) {
                        world.model.missionDark = true
                    }

                    try? await Task.sleep(for: .milliseconds(700))

                    world.beginMission()

                    withAnimation {
                        world.model.hudStage = .mission
                    }
                }
                .transition(.opacity)

            case .mission:
                EmptyView()
            }

            VStack {
                topBar

                Spacer()

                status

                if world.model.hudStage == .mission,
                   world.model.missionDialogueVisible {
                    MissionChatBubbleView(
                        lines: world.model.missionDialogueLines,
                        onFinishedAllLines: {
                            finishMissionDialogue()
                        }
                    )
                    .id(world.model.missionDialogueID)
                    .padding(.bottom, 8)
                }

                if world.model.hudStage == .mission {
                    controls
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .onChange(of: world.model.scanReady) { _, isReady in
            if isReady {
                sfx.scanDone()

                withAnimation {
                    world.model.hudStage = .scanCompletePrompt
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
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
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 12)
        }
    }

    private var controls: some View {
        HStack {
            if world.model.mangoEatReady {
                eatButton
                    .transition(.scale.combined(with: .opacity))
            } else {
                waveButton
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(
            .easeInOut(duration: 0.2),
            value: world.model.mangoEatReady
        )
    }

    private var waveButton: some View {
        Button {
            sfx.tap()
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
            sfx.tap()
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
                .stroke(.white.opacity(0.45), lineWidth: 1)
                .frame(width: 82, height: 82)

            Circle()
                .stroke(.white.opacity(0.35), lineWidth: 1)
                .frame(width: 40, height: 40)

            Rectangle()
                .fill(.white.opacity(0.45))
                .frame(width: 1, height: 94)

            Rectangle()
                .fill(.white.opacity(0.45))
                .frame(width: 94, height: 1)

            Circle()
                .fill(.white.opacity(0.8))
                .frame(width: 5, height: 5)

            if world.model.hudStage == .scanning {
                Text("\(Int((world.model.scanProgress * 100).rounded()))%")
                    .font(
                        .system(
                            size: 12,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white.opacity(0.82))
                    .offset(y: 67)

                scanTurn
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var scanTurn: some View {
        switch world.model.scanTurn {
        case .left:
            HStack(spacing: 0) {
                Image(systemName: "chevron.left")
                Image(systemName: "chevron.left")
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.white.opacity(0.82))
            .offset(x: -86)

        case .right:
            HStack(spacing: 0) {
                Image(systemName: "chevron.right")
                Image(systemName: "chevron.right")
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.white.opacity(0.82))
            .offset(x: 86)

        case .none:
            EmptyView()
        }
    }

    private func finishMissionDialogue() {
        withAnimation {
            world.dismissMissionDialogue()
        }

        guard world.model.missionComplete else { return }

        Task { @MainActor in
            world.clearActiveWave()
            world.clearTraces()

            await world.stop()

            withAnimation(.easeInOut(duration: 0.25)) {
                world.model.showMissionCompleteCard = true
            }
        }
    }

    private func startQuizTransition() {
        sfx.tap()
        sfx.quizBgm()

        world.model.showMissionCompleteCard = false
        world.model.showQuiz = false
        world.model.quizAnswered = false
        world.model.quizCorrect = false
        world.model.quizTransitionID += 1

        withAnimation(.easeInOut(duration: 0.2)) {
            world.model.missionDark = false
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))

            world.model.missionDark = true

            try? await Task.sleep(for: .milliseconds(700))

            world.model.showQuiz = true
        }
    }

    private func restartMission() {
        sfx.sessionBgm()

        withAnimation {
            scanIntroDone = false
        }

        Task { @MainActor in
            await world.restartMission()
        }
    }
}
