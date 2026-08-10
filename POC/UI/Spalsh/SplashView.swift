//
//  SplashView.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
//

import SwiftUI

struct SplashView: View {
    private enum Phase {
        case initial
        case title
        case hideTitle
        case tagline
    }

    let onFinished: () -> Void

    @State private var phase:
        Phase = .initial

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 6) {
                Text("UAR")
                    .font(
                        .largeTitle
                        .weight(.bold)
                    )

                Text("Ultrasonic AR")
                    .font(
                        .title2
                        .weight(.medium)
                    )
                    .foregroundStyle(
                        .secondary
                    )
            }
            .opacity(
                titleOpacity
            )
            .scaleEffect(
                phase == .initial
                ? 0.92
                : 1
            )

            Text(
                "Ready to explore sound?"
            )
            .font(
                .largeTitle
                .weight(.bold)
            )
            .multilineTextAlignment(
                .center
            )
            .opacity(
                taglineOpacity
            )
            .offset(
                y:
                    phase == .tagline
                    ? 0
                    : 6
            )
        }
        .padding(
            .horizontal,
            32
        )
        .preferredColorScheme(.light)
        .task {
            withAnimation(
                .easeOut(
                    duration: 0.6
                )
            ) {
                phase = .title
            }

            try? await Task.sleep(
                for: .seconds(1.3)
            )

            withAnimation(
                .easeInOut(
                    duration: 0.4
                )
            ) {
                phase = .hideTitle
            }

            try? await Task.sleep(
                for: .seconds(0.3)
            )

            withAnimation(
                .easeOut(
                    duration: 0.5
                )
            ) {
                phase = .tagline
            }

            try? await Task.sleep(
                for: .seconds(0.9)
            )

            onFinished()
        }
    }

    private var titleOpacity: Double {
        switch phase {
        case .initial:
            0

        case .title:
            1

        case .hideTitle,
             .tagline:
            0
        }
    }

    private var taglineOpacity: Double {
        phase == .tagline
        ? 1
        : 0
    }
}

#Preview {
    SplashView(
        onFinished: {}
    )
}
