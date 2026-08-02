//
//  ControlsView.swift
//  POC
//
//  Created by Asaryun on 02/08/26.
//
import SwiftUI

struct ControlsView: View {
    @ObservedObject var vm: ARVM

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                controlButton(title: "Place", systemImage: "hand.tap.fill", prominent: true, tint: .blue, disabled: !vm.state.lidarOK) { vm.spawn() }
                controlButton(title: "Wave", systemImage: "waveform", prominent: false, tint: .cyan, disabled: !vm.state.hasBot) { vm.pulse() }
                controlButton(title: "Clear", systemImage: "trash", prominent: false, tint: .red, disabled: !vm.state.hasBot) { vm.clear() }
            }

            Text(vm.state.hasBot ? "drag to move · twist to rotate" : "aim at floor / table")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func controlButton(
        title: String,
        systemImage: String,
        prominent: Bool,
        tint: Color,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage).font(.system(size: 17))
                Text(title).font(.caption2.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .buttonStyle(.borderedProminent)
        .tint(prominent ? tint : tint.opacity(0.18))
        .foregroundStyle(prominent ? .white : tint)
        .disabled(disabled)
    }
}
