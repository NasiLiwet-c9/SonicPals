//
//  MainView.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
//

import SwiftUI
import UIKit

@MainActor
struct MainView: View {
    let onBack: () -> Void

    @State private var world =
        ECSWorld()

    @State private var showInfo =
        false

    var body: some View {
        ZStack {
            ARViewBox(world: world)
                .ignoresSafeArea()

            FPShade(
                dim: world.model.dimOn
            )

            WaveRings(
                seq: world.model.waveSeq
            )

            HUDView(
                world: world,
                onBack: onBack,
                onInfo: {
                    showInfo = true
                }
            )
        }
        .preferredColorScheme(.dark)
        .sheet(
            isPresented: $showInfo
        ) {
            OnboardView(
                buttonText: "Done"
            ) {
                showInfo = false
            }
        }
        .task {
            for await _ in
                NotificationCenter.default
                    .notifications(
                        named:
                            UIApplication
                                .didReceiveMemoryWarningNotification
                    ) {
                world.perform(
                    .memoryWarning
                )
            }
        }
    }
}
