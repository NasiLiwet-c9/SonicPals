//
//  RootView.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import SwiftUI

struct RootView: View {
    private enum Stage {
        case splash
        case onboard
        case main
    }

    @State private var stage: Stage = .splash

    var body: some View {
        ZStack {
            switch stage {
            case .splash:
                SplashView {
                    move(to: .onboard)
                }
                .transition(.opacity)

            case .onboard:
                OnboardView(
                    buttonText: "Start"
                ) {
                    move(to: .main)
                }
                .transition(.opacity)

            case .main:
                MainView {
                    move(to: .onboard)
                }
                .transition(.opacity)
            }
        }
    }

    private func move(
        to next: Stage
    ) {
        withAnimation(
            .easeInOut(
                duration: 0.35
            )
        ) {
            stage = next
        }
    }
}

#Preview {
    RootView()
}
