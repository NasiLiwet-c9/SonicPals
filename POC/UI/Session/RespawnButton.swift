//
//  RespawnButton.swift
//  POC
//
//  Created by Shan Newcastle on 04/09/26.
//

import SwiftUI

/// Moves the tree somewhere new when the player has swept the room and
/// found nothing.
///
/// Its own control rather than a line in Battiw's bubble, which is a
/// narrator you dismiss. The hint waits until the hunt has dragged, so it
/// never reads as "you were meant to press this".
struct RespawnButton: View {
    let uiScale: CGFloat
    let onRespawn: () -> Void

    @State private var showHint = false

    var body: some View {
        HStack(alignment: .top, spacing: UICfg.Respawn.gap * uiScale) {
            if showHint {
                hint
                    .transition(
                        .move(edge: .trailing).combined(with: .opacity)
                    )
            }

            button
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showHint)
        .task {
            try? await Task.sleep(for: .seconds(UICfg.Respawn.hintAfterS))

            guard !Task.isCancelled else { return }

            showHint = true
        }
    }

    private var button: some View {
        Button {
            showHint = false
            onRespawn()
        } label: {
            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                .font(
                    .system(
                        size: UICfg.Respawn.icon * uiScale,
                        weight: .bold
                    )
                )
                .foregroundStyle(.white)
                .frame(
                    width: UICfg.Respawn.size * uiScale,
                    height: UICfg.Respawn.size * uiScale
                )
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.28), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Hide the tree somewhere new")
        .accessibilityHint("Sweeps the room again and moves the tree")
    }

    private var hint: some View {
        Text("Can't find the tree?\nTap to hide it somewhere new!")
            .font(
                .system(
                    size: UICfg.Respawn.txt * uiScale,
                    weight: .semibold
                )
            )
            .multilineTextAlignment(.trailing)
            .foregroundStyle(.white)
            .padding(.horizontal, 12 * uiScale)
            .padding(.vertical, 8 * uiScale)
            .background(.ultraThinMaterial, in: Capsule())
            .fixedSize()
            .onTapGesture {
                showHint = false
            }
    }
}
