//
//  HUDView+Controls.swift
//  SonicPals
//
//  Created by Shan Newcastle on 08/09/26.
//

import SwiftUI

/// The bar, the buttons, and what they kick off
extension HUDView {
    func topBar(_ scale: CGFloat) -> some View {
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
    func status(
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
                .padding(.horizontal, 14 * scale)
                .padding(.vertical, 8 * scale)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 12 * scale)
        }
    }

    var controls: some View {
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

    var waveButton: some View {
        PingButton(
            enabled: world.model.canWave && !world.model.coachStep.locksInput
        ) {
            sfx.tap()
            world.perform(.sendWave)
        }
    }

    var eatButton: some View {
        Button {
            sfx.tap()
            world.perform(.eatMango)
        } label: {
            Image("eat-btn")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 108, height: 108)
        }
        .buttonStyle(.plain)
        .glassEffect()
        .disabled(world.model.coachStep.locksInput)
        .accessibilityLabel("Eat mango")
    }

    func startQuizTransition() {
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
            try? await Task.sleep(for: .milliseconds(220))

            sfx.popup()

            withAnimation(
                .spring(response: 0.45, dampingFraction: 0.78)
            ) {
                world.model.showQuiz = true
            }
        }
    }

    func restartMission() {
        Task { @MainActor in
            await world.mission.restart()
        }
    }
}
