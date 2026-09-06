//
//  CoachSpotlight.swift
//  POC
//
//  Created by Shan Newcastle on 04/09/26.
//

import SwiftUI

/// Darkens everything but the control being asked for. A ring alone is
/// easy to miss on a camera feed
///
/// The hole closes onto the button rather than the screen just going
/// dark, which reads as a glitch
struct CoachSpotlight: View {
    let rect: CGRect

    @State private var pulse = false
    @State private var focused = false

    private let violet = Color(red: 0.62, green: 0.52, blue: 1)

    private var diameter: CGFloat {
        max(rect.width, rect.height) * 1.15
    }

    /// How wide it starts before closing in
    private var openScale: CGFloat {
        focused ? 1 : 4.2
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(focused ? 0.66 : 0))
                .reverseMask {
                    Circle()
                        .frame(
                            width: diameter * openScale,
                            height: diameter * openScale
                        )
                        .position(x: rect.midX, y: rect.midY)
                }

            Circle()
                .stroke(violet.opacity(focused ? 0.95 : 0), lineWidth: 3)
                .frame(
                    width: diameter * openScale,
                    height: diameter * openScale
                )
                .position(x: rect.midX, y: rect.midY)

            // Only starts once the hole has landed
            if focused {
                Circle()
                    .stroke(violet.opacity(pulse ? 0 : 0.6), lineWidth: 3)
                    .frame(
                        width: diameter * (pulse ? 1.5 : 1),
                        height: diameter * (pulse ? 1.5 : 1)
                    )
                    .position(x: rect.midX, y: rect.midY)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .task {
            withAnimation(.easeOut(duration: 0.55)) {
                focused = true
            }

            try? await Task.sleep(for: .milliseconds(560))

            guard !Task.isCancelled else { return }

            withAnimation(
                .easeOut(duration: 1.1).repeatForever(autoreverses: false)
            ) {
                pulse = true
            }
        }
    }
}

private extension View {
    /// Cuts the shape out instead of keeping it
    func reverseMask<Mask: View>(
        @ViewBuilder _ mask: () -> Mask
    ) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: .center) {
                    mask().blendMode(.destinationOut)
                }
        }
    }
}
