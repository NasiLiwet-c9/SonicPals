//
//  HUDView.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//  Updated by Asaryun on 13/08/26
//

import SwiftUI

/// Reports where the bottom controls ended up, so the coach spotlight can
/// be punched out at exactly that spot.
private struct ControlBounds: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(
        value: inout Anchor<CGRect>?,
        nextValue: () -> Anchor<CGRect>?
    ) {
        value = nextValue() ?? value
    }
}

struct HUDView: View {
    let world: ECSWorld

    let onBack: () -> Void

    @State private var controlBounds: Anchor<CGRect>?

    private let sfx = SfxSvc.shared

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let scale = UICfg.s(size)

            ZStack {
                reticle(scale)

                /*
                #if DEBUG
                Button("SKIP TO COMPLETION") {
                    world.model.missionComplete = true
                    world.model.showMissionCompleteCard = true
                    world.model.missionDialogueVisible = false
                }
                .buttonStyle(.borderedProminent)
                .position(x: 120, y: 100)
                .zIndex(100)
                #endif
                */

                if world.model.showMissionCompleteCard {
                    MissionCompleteCardView {
                        startQuizTransition()
                    }
                    .transition(
                        .scale(scale: 0.78)
                        .combined(with: .opacity)
                    )
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
                    .transition(
                        .scale(scale: 0.76)
                        .combined(with: .opacity)
                    )
                    .zIndex(20)
                }

                if world.model.eatAnimationVisible {
                    eatAnimation
                        .id(world.model.eatAnimationID)
                        .task(
                            id: world.model.eatAnimationID
                        ) {
                            try? await Task.sleep(
                                for: .milliseconds(
                                    UICfg.Eat.ms
                                )
                            )

                            world.model.eatAnimationVisible = false
                        }
                        .transition(.opacity)
                }

                switch world.model.hudStage {
                case .scanning:
                    EmptyView()

                case .scanCompletePrompt:
                    Color.clear
                        .task {
                            world.endScan()
                            world.model.missionDark = false

                            try? await Task.sleep(
                                for: .milliseconds(180)
                            )

                            withAnimation {
                                world.model.hudStage = .transitioning
                            }
                        }

                case .transitioning:
                    scanTransition
                        .task {
                            world.model.missionDark = false

                            try? await Task.sleep(
                                for: .milliseconds(
                                    UICfg.Trans.preMs
                                )
                            )

                            withAnimation(
                                .easeInOut(
                                    duration: UICfg.Trans.fade
                                )
                            ) {
                                world.model.missionDark = true
                            }

                            try? await Task.sleep(
                                for: .milliseconds(
                                    UICfg.Trans.postMs
                                )
                            )

                            world.mission.begin()

                            withAnimation {
                                world.model.hudStage = .mission
                            }
                        }
                        .transition(.opacity)

                case .mission:
                    EmptyView()
                }

                if let controlBounds,
                   world.model.coachStep.spotlight != .none {
                    CoachSpotlight(
                        // The scrim ignores the safe area, so it draws in
                        // screen space; the anchor resolves in the HUD's.
                        rect: geo[controlBounds].offsetBy(
                            dx: geo.frame(in: .global).minX,
                            dy: geo.frame(in: .global).minY
                        )
                    )
                        .transition(.opacity)
                        .zIndex(5)
                }

                if !world.model.coachLine.isEmpty {
                    VStack {
                        CoachBubble(
                            line: world.model.coachLine,
                            lineID: world.model.coachLineID,
                            uiScale: scale
                        )
                        .padding(.top, UICfg.Coach.top * scale)

                        Spacer()
                    }
                    .transition(.opacity)
                    .zIndex(6)
                }

                VStack {
                    topBar(scale)

                    Spacer()

                    status(scale)

                    if world.model.hudStage == .mission,
                       world.model.missionDialogueVisible {

                        MissionChatBubbleView(
                            text: world.model.missionDialogueText,
                            lineID: world.model.missionDialogueID,
                            uiScale: scale
                        )
                        .transition(.opacity)
                        .padding(
                            .bottom,
                            UICfg.Sess.botBottom * scale
                        )
                    }

                    if world.model.hudStage == .mission,
                       !world.model.missionComplete {
                        controls
                            .anchorPreference(
                                key: ControlBounds.self,
                                value: .bounds
                            ) { $0 }
                    }
                }
                .padding(
                    .horizontal,
                    28 * scale
                )
                .padding(
                    .top,
                    10 * scale
                )
                .padding(
                    .bottom,
                    24 * scale
                )
                .animation(
                    .easeInOut(duration: 0.22),
                    value: world.model.missionDialogueVisible
                )
            }
            .frame(
                width: size.width,
                height: size.height
            )
            .onPreferenceChange(ControlBounds.self) { bounds in
                controlBounds = bounds
            }
            .animation(
                .easeInOut(duration: 0.35),
                value: world.model.coachStep.spotlight
            )
        }
        .onChange(
            of: world.model.scanReady
        ) { _, isReady in
            guard world.model.hudStage == .scanning else {
                return
            }

            if isReady {
                sfx.scanDone()

                withAnimation {
                    world.model.hudStage = .scanCompletePrompt
                }
            }
        }
    }

    private var eatAnimation: some View {
        GeometryReader { geo in
            let size = geo.size
            let w = UICfg.v(
                UICfg.Eat.gifW,
                size
            )

            let h = w * (882.0 / 413.0)

            GIFImageView(
                name: "eat-animation",
                contentMode: .scaleAspectFit
            )
            .frame(
                width: w,
                height: h
            )
            .position(
                x: size.width / 2,
                y: size.height / 2
                    + UICfg.y(
                        UICfg.Eat.gifY,
                        size
                    )
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var scanTransition: some View {
        GeometryReader { geo in
            let size = geo.size
            let w = UICfg.v(
                UICfg.Trans.gifW,
                size
            )

            let h = w * (874.0 / 404.0)

            ZStack {
                GIFImageView(
                    name: "light-to-dark-transition",
                    contentMode: .scaleAspectFit
                )
                .frame(
                    width: w,
                    height: h
                )
                .position(
                    x: size.width / 2,
                    y: size.height / 2
                        + UICfg.y(
                            UICfg.Trans.gifY,
                            size
                        )
                )

                Color.black
                    .opacity(
                        world.model.missionDark
                            ? UICfg.Trans.dim
                            : 0
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func topBar(_ scale: CGFloat) -> some View {
        HStack(alignment: .top) {
            if world.model.hudStage == .mission {
                MangoCounterView(
                    eatenCount: world.model.mangoEatenCount,
                    target: world.model.missionMangoTarget
                )
            }

            Spacer()

            if world.model.hudStage == .mission,
               !world.model.missionComplete,
               !world.model.showQuiz,
               !world.model.coachStep.locksInput {
                RespawnButton(uiScale: scale) {
                    sfx.tap()
                    world.respawnTarget()
                }
                .id(world.model.mangoEatenCount)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private func status(
        _ scale: CGFloat
    ) -> some View {
        if !world.model.msg.isEmpty {
            Text(world.model.msg)
                .font(
                    .system(
                        size: UICfg.Sess.statusTxt * scale,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.white)
                .padding(
                    .horizontal,
                    14 * scale
                )
                .padding(
                    .vertical,
                    8 * scale
                )
                .background(
                    .ultraThinMaterial,
                    in: Capsule()
                )
                .padding(
                    .bottom,
                    12 * scale
                )
        }
    }

    private var controls: some View {
        HStack {
            if world.model.mangoEatReady {
                eatButton
                    .transition(
                        .scale.combined(
                            with: .opacity
                        )
                    )
            } else {
                waveButton
                    .transition(
                        .scale.combined(
                            with: .opacity
                        )
                    )
            }
        }

        .animation(
            .easeInOut(duration: 0.2),
            value: world.model.mangoEatReady
        )
    }

    private var waveButton: some View {
        PingButton(
            enabled: world.model.canWave
                && !world.model.coachStep.locksInput
        ) {
            sfx.tap()
            world.perform(.sendWave)
        }
    }

    private var eatButton: some View {
        Button {
            sfx.tap()
            world.perform(.eatMango)
        } label: {
            Image("eat-btn")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(
                    contentMode: .fit
                )
                .frame(
                    width: 108,
                    height: 108
                )
        }
        .buttonStyle(.plain)
        .glassEffect()
        .disabled(world.model.coachStep.locksInput)
        .accessibilityLabel("Eat mango")
    }

    private func reticle(
        _ scale: CGFloat
    ) -> some View {
        ZStack {
            Circle()
                .stroke(
                    .white.opacity(0.45),
                    lineWidth: 1
                )
                .frame(
                    width: 82 * scale,
                    height: 82 * scale
                )

            Circle()
                .stroke(
                    .white.opacity(0.35),
                    lineWidth: 1
                )
                .frame(
                    width: 40 * scale,
                    height: 40 * scale
                )

            Rectangle()
                .fill(
                    .white.opacity(0.45)
                )
                .frame(
                    width: 1,
                    height: 94 * scale
                )

            Rectangle()
                .fill(
                    .white.opacity(0.45)
                )
                .frame(
                    width: 94 * scale,
                    height: 1
                )

            Circle()
                .fill(.white)
                .frame(
                    width: 5 * scale,
                    height: 5 * scale
                )

            if world.model.hudStage == .scanning {
                Text(
                    "\(Int((world.model.scanProgress * 100).rounded()))%"
                )
                .font(
                    .system(
                        size: UICfg.Scan.pctTxt * scale,
                        weight: .heavy
                    )
                )
                .foregroundStyle(.white)
                .padding(
                    .horizontal,
                    UICfg.Scan.pctPadX * scale
                )
                .padding(
                    .vertical,
                    UICfg.Scan.pctPadY * scale
                )
                .background(
                    Color.black
                        .opacity(
                            UICfg.Scan.pctBg
                        ),
                    in: Capsule()
                )
                .shadow(
                    color: .black.opacity(0.5),
                    radius: 3
                )
                .offset(
                    y: UICfg.Scan.pctY * scale
                )

                scanTurn(scale)
            }

        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func scanTurn(
        _ scale: CGFloat
    ) -> some View {
        switch world.model.scanTurn {
        case .left:
            HStack(spacing: 0) {
                Image(
                    systemName: "chevron.left"
                )

                Image(
                    systemName: "chevron.left"
                )
            }
            .font(
                .system(
                    size: UICfg.Scan.arrTxt * scale,
                    weight: .heavy
                )
            )
            .foregroundStyle(.white)
            .shadow(
                color: .black.opacity(0.55),
                radius: 2
            )
            .offset(
                x: -UICfg.Scan.arrX * scale
            )

        case .right:
            HStack(spacing: 0) {
                Image(
                    systemName: "chevron.right"
                )

                Image(
                    systemName: "chevron.right"
                )
            }
            .font(
                .system(
                    size: UICfg.Scan.arrTxt * scale,
                    weight: .heavy
                )
            )
            .foregroundStyle(.white)
            .shadow(
                color: .black.opacity(0.55),
                radius: 2
            )
            .offset(
                x: UICfg.Scan.arrX * scale
            )

        case .none:
            EmptyView()
        }
    }

    private func startQuizTransition() {
        sfx.tap()
        sfx.quizBgm()

        world.model.showQuiz = false
        world.model.quizAnswered = false
        world.model.quizCorrect = false
        world.model.quizTransitionID += 1

        withAnimation(
            .easeInOut(duration: 0.18)
        ) {
            world.model.showMissionCompleteCard = false
        }

        Task { @MainActor in
            try? await Task.sleep(
                for: .milliseconds(220)
            )

            sfx.popup()

            withAnimation(
                .spring(
                    response: 0.45,
                    dampingFraction: 0.78
                )
            ) {
                world.model.showQuiz = true
            }
        }
    }

    private func restartMission() {
        Task { @MainActor in
            await world.mission.restart()
        }
    }
}
