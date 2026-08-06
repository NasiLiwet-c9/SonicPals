//
//  ToggleBar.swift
//  POC
//
//  Created by Shanon Newcastle on 03/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

import SwiftUI

struct ToggleBar: View {
    let world: ECSWorld

    var body: some View {
        HStack(spacing: 10) {
            Spacer()

            iconButton(
                icon:
                    world.model.viewMode == .first
                    ? "person.crop.circle.fill"
                    : "cube.transparent",
                tint: .indigo,
                isOn: world.model.viewMode == .first,
                disabled: !world.model.lidarOK,
                label:
                    world.model.viewMode == .first
                    ? "Switch to third person"
                    : "Switch to first person"
            ) {
                world.perform(.toggleView)
            }

            iconButton(
                icon:
                    world.model.pointsOn
                    ? "circle.grid.3x3.fill"
                    : "circle.grid.3x3",
                tint: .purple,
                isOn: world.model.pointsOn,
                disabled:
                    !world.model.hasWave
                    || world.model.viewMode == .first,
                label:
                    world.model.pointsOn
                    ? "Hide all points"
                    : "Show all points"
            ) {
                world.perform(.togglePoints)
            }

            iconButton(
                icon:
                    world.model.meshOn
                    ? "eye"
                    : "eye.slash",
                tint: .blue,
                isOn: world.model.meshOn,
                disabled:
                    !world.model.lidarOK
                    || world.model.viewMode == .first,
                label:
                    world.model.meshOn
                    ? "Hide mesh"
                    : "Show mesh"
            ) {
                world.perform(.toggleMesh)
            }
        }
    }

    private func iconButton(
        icon: String,
        tint: Color,
        isOn: Bool,
        disabled: Bool,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isOn ? Color.white : tint)
                .frame(width: 44, height: 44)
                .background(isOn ? tint : Color.clear, in: Circle())
                .background(.ultraThinMaterial, in: Circle())
        }
        .disabled(disabled)
        .accessibilityLabel(label)
    }
}
