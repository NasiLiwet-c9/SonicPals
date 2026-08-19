//
//  MainView.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import SwiftUI
import UIKit

@MainActor
struct MainView: View {
    let onBack: () -> Void

    @State private var world = ECSWorld()
    @State private var showInfo = false

    var body: some View {
        ZStack {
            RealitySceneView(world: world)
                .ignoresSafeArea()

            if world.model.missionDark
                && world.model.hudStage != .mission {
                FPShade(dim: world.model.dimOn)
                    .transition(.opacity)
            }

            if world.model.hudStage == .mission {
                WaveRings(seq: world.model.waveSeq)
            }

            HUDView(
                world: world,
                onBack: onBack,
                onInfo: {
                    showInfo = true
                }
            )
        }
        .overlay {
            ForceSpawnSecret(world: world)
        }
        .animation(
            .easeInOut(duration: 0.35),
            value: world.model.missionDark
        )
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showInfo) {
            OnboardView(buttonText: "Done") {
                showInfo = false
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(
                named: UIApplication.didReceiveMemoryWarningNotification
            ) {
                world.perform(.memoryWarning)
            }
        }
    }
}
