//
//  Transition.swift
//  POC
//
//  Created by Asaryun on 07/08/26.
//
//  Owns the splash -> onboarding transition. Swap this in as your
//  app's top-level view (in POCApp.swift) in place of whatever you
//  show first today.
//

import SwiftUI

struct Transition: View {
    private enum Stage {
        case splash
        case onboarding
        case main
    }
    
    @State private var stage: Stage = .splash
    
    var body: some View {
        ZStack {
            switch stage {
            case .splash:
                SplashScreen {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        stage = .onboarding
                    }
                }
                .transition(.opacity)
                
            case .onboarding:
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        stage = .main
                    }
                }
                .transition(.opacity)
                
            case .main:
                MainView()
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    Transition()
}
