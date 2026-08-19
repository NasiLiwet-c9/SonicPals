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
            if world.model.missionComplete {
                endBackground
                    .transition(.opacity)
            } else {
                RealitySceneView(world: world)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            if world.model.missionDark
                && world.model.hudStage != .mission {
                FPShade(dim: world.model.dimOn)
                    .transition(.opacity)
            }

            if world.model.hudStage == .mission,
               !world.model.missionComplete {
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
        .animation(
            .easeInOut(duration: 0.3),
            value: world.model.missionComplete
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

    private var endBackground: some View {
        RadialGradient(
            stops: [
                .init(color: Color(red: 0.055, green: 0.065, blue: 0.09), location: 0),
                .init(color: Color(red: 0.025, green: 0.03, blue: 0.045), location: 0.55),
                .init(color: .black, location: 1)
            ],
            center: .center,
            startRadius: 20,
            endRadius: 700
        )
        .ignoresSafeArea()
    }
}
