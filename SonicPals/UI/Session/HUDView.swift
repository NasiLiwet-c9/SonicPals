//
//  HUDView.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//  Updated by Asaryun on 13/08/26
//

import SwiftUI

/// Reports where the bottom controls ended up, so the coach spotlight can
/// be punched out at exactly that spot
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

    let sfx = SfxSvc.shared

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
                    .transition(.scale(scale: 0.78) .combined(with: .opacity))
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
                    .transition(.scale(scale: 0.76) .combined(with: .opacity))
                    .zIndex(20)
                }

                if world.model.eatAnimationVisible {
                    eatAnimation
                        .id(world.model.eatAnimationID)
                        .task(
                            id: world.model.eatAnimationID
                        ) {
                            try? await Task.sleep(for: .milliseconds(UICfg.Eat.ms))

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

                            try? await Task.sleep(for: .milliseconds(180))

                            withAnimation {
                                world.model.hudStage = .transitioning
                            }
                        }

                case .transitioning:
                    scanTransition
                        .task {
                            world.model.missionDark = false

                            try? await Task.sleep(for: .milliseconds(UICfg.Trans.preMs))

                            withAnimation(
                                .easeInOut(duration: UICfg.Trans.fade)
                            ) {
                                world.model.missionDark = true
                            }

                            try? await Task.sleep(for: .milliseconds(UICfg.Trans.postMs))

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
                        // screen space, the anchor resolves in the HUD's
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
                        .padding(.bottom, UICfg.Sess.botBottom * scale)
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
                .padding(.horizontal, 28 * scale)
                .padding(.top, 10 * scale)
                .padding(.bottom, 24 * scale)
                .animation(
                    .easeInOut(duration: 0.22),
                    value: world.model.missionDialogueVisible
                )
            }
            .frame(width: size.width, height: size.height)
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
                return }

            if isReady {
                sfx.scanDone()

                withAnimation {
                    world.model.hudStage = .scanCompletePrompt
                }
            }
        }
    }
}
