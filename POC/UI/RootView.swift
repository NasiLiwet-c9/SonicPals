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

    private let sfx = SfxSvc.shared

    var body: some View {
        ZStack {
            switch stage {
            case .home:
                HomeView(
                    onStart: {
                        sfx.tap()
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
        .task {
            sfx.menuBgm()
        }
    }

    private func move(to next: Stage) {
        switch next {
        case .home:
            sfx.menuBgm()

        case .splash, .main:
            sfx.sessionBgm()
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            stage = next
        }
    }
}

#Preview {
    RootView()
}
