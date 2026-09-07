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
        case map
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
                        sfx.tap()
                        move(to: .map)
                    }
                )
                .transition(.opacity)

            case .map:
                MapView {
                    sfx.tap()
                    move(to: .home)
                }
                .transition(.opacity)

            case .splash:
                SplashView {
                    move(to: .main)
                }
                .transition(.opacity)

            case .main:
                MainView {
                    move(to: .home)
                }
                .transition(.opacity)
            }
        }
        .sonicPalsTypography()
        .task {
            sfx.menuBgm()
        }
        .task(id: stage) {
            // The loading screen is here to cover this: pulling in the
            // tree scene and building the first target both stall the
            // main actor, and doing it later stalls the spawn instead
            guard stage == .splash else { return }

            if await TargetAssetSvc.shared.prepare() {
                await TargetAssetSvc.shared.prewarm()
            }
        }
    }

    private func move(to next: Stage) {
        switch next {
        case .home, .map:
            sfx.menuBgm()

        case .splash:
            sfx.stopBgm()

        case .main:
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
