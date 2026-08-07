//
//  SplashScreen.swift
//  POC
//
//  Created by Asaryun on 07/08/26.
//

import SwiftUI

struct SplashScreen: View {
    private enum Phase {
        case initial
        case titleIn
        case titleOut
        case taglineIn
    }

    var onFinished: () -> Void

    @State private var phase: Phase = .initial

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            // Title block — centered on its own, independent of the tagline.
            VStack(spacing: 4) {
                Text("UAR")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)

                Text("Ultrasonic Assault Rifle")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .opacity(titleOpacity)
            .scaleEffect(phase == .initial ? 0.92 : 1)

            // Tagline block — occupies the exact same centered position,
            // so it lands dead-center once the title has faded out.
            Text("Ready to learn?")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)
                .opacity(taglineOpacity)
                .offset(y: phase == .taglineIn ? 0 : 6)
        }
        .padding(.horizontal, 32)
        .multilineTextAlignment(.center)
        .preferredColorScheme(.light)
        .task {
            withAnimation(.easeOut(duration: 0.6)) {
                phase = .titleIn
            }

            try? await Task.sleep(for: .seconds(1.4))

            withAnimation(.easeInOut(duration: 0.45)) {
                phase = .titleOut
            }

            try? await Task.sleep(for: .seconds(0.35))

            withAnimation(.easeOut(duration: 0.55)) {
                phase = .taglineIn
            }

            try? await Task.sleep(for: .seconds(1))

            onFinished()
        }
    }

    private var titleOpacity: Double {
        switch phase {
        case .initial: 0
        case .titleIn: 1
        case .titleOut, .taglineIn: 0
        }
    }

    private var taglineOpacity: Double {
        phase == .taglineIn ? 1 : 0
    }
}

#Preview {
    SplashScreen(onFinished: {})
}
