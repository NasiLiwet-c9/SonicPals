//
//  SessionGateView.swift
//  SonicPals
//
//  Created by Shan Newcastle on 07/09/26.
//

import SwiftUI
import UIKit

/// Stands in front of the live session while it comes up, and stays there
/// when it cannot run at all
///
/// The camera prompt lands on the mission screen, which is deliberately
/// unlit, so without this a refused or pending camera looks like a hang
struct SessionGateView: View {
    let state: AppModel.SessionState
    let onBack: () -> Void

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let scale = UICfg.s(size)

            ZStack {
                Color(red: 0.07, green: 0.06, blue: 0.16)
                    .ignoresSafeArea()

                switch state {
                case .starting:
                    waking(scale)

                case .noCamera:
                    blocked(
                        scale,
                        mascot: "heranbattiw-with-eyeglass",
                        title: "Battiw can't see!",
                        body: "Sonic Pals needs the camera to look around the room. Switch it on in Settings, then come back.",
                        settings: true
                    )

                case .noLiDAR:
                    blocked(
                        scale,
                        mascot: "soktaubattiw-with-eyeglass",
                        title: "This phone can't hear echoes",
                        body: "Sonic Pals needs a phone with a LiDAR scanner to feel the walls, like an iPhone Pro.",
                        settings: false
                    )

                case .ready:
                    EmptyView()
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private func waking(_ scale: CGFloat) -> some View {
        VStack(spacing: UICfg.Gate.gap * scale) {
            ProgressView()
                .controlSize(.large)
                .tint(.white)

            Text("Getting Battiw's ears ready...")
                .font(
                    .system(
                        size: UICfg.Gate.bodyTxt * scale,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private func blocked(
        _ scale: CGFloat,
        mascot: String,
        title: String,
        body: String,
        settings: Bool
    ) -> some View {
        VStack(spacing: UICfg.Gate.gap * scale) {
            AssetImageView(name: mascot)
                .frame(
                    width: UICfg.Gate.mascot * scale,
                    height: UICfg.Gate.mascot * scale
                )

            Text(title)
                .font(
                    .system(
                        size: UICfg.Gate.titleTxt * scale,
                        weight: .heavy
                    )
                )
                .foregroundStyle(.white)

            Text(body)
                .font(
                    .system(
                        size: UICfg.Gate.bodyTxt * scale,
                        weight: .medium
                    )
                )
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, UICfg.Gate.padX * scale)

            VStack(spacing: UICfg.Gate.btnGap * scale) {
                if settings {
                    Button("Open Settings") {
                        openSettings()
                    }
                    .buttonStyle(GateButtonStyle(scale: scale, filled: true))
                }

                Button("Back to menu", action: onBack)
                    .buttonStyle(GateButtonStyle(scale: scale, filled: false))
            }
            .padding(.top, UICfg.Gate.btnTop * scale)
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return }

        UIApplication.shared.open(url)
    }
}

private struct GateButtonStyle: ButtonStyle {
    let scale: CGFloat
    let filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(
                .system(
                    size: UICfg.Gate.btnTxt * scale,
                    weight: .heavy
                )
            )
            .foregroundStyle(filled ? .black : .white)
            .frame(
                width: UICfg.Gate.btnW * scale,
                height: UICfg.Gate.btnH * scale
            )
            .background {
                Capsule()
                    .fill(filled ? Color.yellow : Color.white.opacity(0.14))
            }
            .overlay {
                Capsule()
                    .stroke(.white.opacity(filled ? 0 : 0.3), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

#Preview("No camera") {
    SessionGateView(state: .noCamera) {}
}

#Preview("Starting") {
    SessionGateView(state: .starting) {}
}
