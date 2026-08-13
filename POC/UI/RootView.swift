//
//  RootView.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//  Updated by Asaryun on 13/08/26

import SwiftUI

struct RootView: View {
    private enum Stage {
        case splash
        case home
//        case onboard
        case main
    }

    @State private var stage: Stage = .home

    var body: some View {
        ZStack {
            switch stage {
            case .home:
                HomeView(
                    onStart: {
                        move(to: .splash)
                    },
                    onSelectMode: {
                        // TODO: hook up mode-selection flow once it exists
                    }
                )
                .transition(.opacity)
                
            case .splash:
                SplashView {
                    move(to: .main)
                }
                .transition(.opacity)

//            case .onboard:
//                OnboardView(
//                    buttonText: "Start"
//                ) {
//                    move(to: .main)
//                }
//                .transition(.opacity)

            case .main:
                MainView {
                    move(to: .home)
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
