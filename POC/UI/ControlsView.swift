//
//  ControlsView.swift
//  POC
//
//  Created by Asaryun on 02/08/26.
//  Updated by Shanon Newcastle on 03/08/26.
//

import SwiftUI

struct ControlsView: View {
    let vm: ARVM
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                controlButton(
                    title: "Place",
                    icon: "hand.tap.fill",
                    tint: .blue,
                    disabled:
                        !vm.state.lidarOK
                    || vm.state.viewMode == .first
                ) {
                    vm.place()
                }
                
                controlButton(
                    title: "Wave",
                    icon: "waveform",
                    tint: .cyan,
                    disabled: !vm.state.canWave
                ) {
                    vm.sendWave()
                }
                
                controlButton(
                    title: "Clear",
                    icon: "trash",
                    tint: .red,
                    disabled: !vm.state.hasObject
                ) {
                    vm.clear()
                }
            }
            
            Text(helpText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }
    
    private var helpText: String {
        if vm.state.viewMode == .first {
            return "FIRST POV · move phone to aim · tap Wave"
        }
        
        if vm.state.hasObject {
            return "THIRD POV · drag to move · twist to rotate"
        }
        
        return "THIRD POV · aim at floor / table · tap Place"
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
                    .font(
                        .system(size: 17)
                    )
                
                Text(title)
                    .font(
                        .caption2.weight(.medium)
                    )
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
