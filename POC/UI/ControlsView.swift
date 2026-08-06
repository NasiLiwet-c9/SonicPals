//
//  ControlsView.swift
//  POC
//
//  Created by Asaryun on 02/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//  Updated by Asaryun on 04/08/26.

import SwiftUI

struct ControlsView: View {
    let world: ECSWorld

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                controlButton(
                    title: "Place",
                    icon: "hand.tap.fill",
                    tint: .blue,
                    disabled:
                        !world.model.lidarOK
                        || world.model.viewMode == .first
                ) {
                    world.perform(.place)
                }

                controlButton(
                    title: "Wave",
                    icon: "waveform",
                    tint: .cyan,
                    disabled: !world.model.canWave
                ) {
                    world.perform(.sendWave)
                }

                controlButton(
                    title: "Clear",
                    icon: "trash",
                    tint: .red,
                    disabled: !world.model.hasObject
                ) {
                    world.perform(.clear)
                }
            }

            Text(helpText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private var helpText: String {
        if world.model.viewMode == .first {
            return "FIRST POV · move phone to aim · tap Wave"
        }

        if world.model.hasObject {
            return "THIRD POV · Place recenters · drag moves · twist rotates"
        }

        return "THIRD POV · tap Place to float Bat3 in front"
    }

    private func controlButton(
        title: String,
        icon: String,
        tint: Color,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 17))

                Text(title)
                    .font(.caption2.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint.opacity(0.22))
        .foregroundStyle(tint)
        .disabled(disabled)
    }
}
