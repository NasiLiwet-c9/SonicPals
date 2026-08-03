//
//  ToggleBar.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 03/08/26.
//

import SwiftUI

struct ToggleBar:
    View {
    
    let vm:
    ARVM
    
    var body:
    some View {
        HStack(
            spacing: 10
        ) {
            Spacer()
            
            iconButton(
                icon:
                    vm.state.viewMode == .first
                ? "person.crop.circle.fill"
                : "cube.transparent",
                tint:
                        .indigo,
                isOn:
                    vm.state.viewMode == .first,
                disabled:
                    !vm.state.lidarOK,
                label:
                    vm.state.viewMode == .first
                ? "Switch to third person"
                : "Switch to first person"
            ) {
                vm.toggleView()
            }
            
            iconButton(
                icon:
                    vm.state.pointsOn
                ? "circle.grid.3x3.fill"
                : "circle.grid.3x3",
                tint:
                        .purple,
                isOn:
                    vm.state.pointsOn,
                disabled:
                    !vm.state.hasWave,
                label:
                    vm.state.pointsOn
                ? "Hide all points"
                : "Show all points"
            ) {
                vm.togglePoints()
            }
            
            iconButton(
                icon:
                    vm.state.meshOn
                ? "eye"
                : "eye.slash",
                tint:
                        .blue,
                isOn:
                    vm.state.meshOn,
                disabled:
                    !vm.state.lidarOK,
                label:
                    vm.state.meshOn
                ? "Hide mesh"
                : "Show mesh"
            ) {
                vm.toggleMesh()
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
        Button(
            action:
                action
        ) {
            Image(
                systemName:
                    icon
            )
            .font(
                .system(
                    size:
                        15,
                    weight:
                            .medium
                )
            )
            .foregroundStyle(
                isOn
                ? Color.white
                : tint
            )
            .frame(
                width:
                    44,
                height:
                    44
            )
            .background(
                isOn
                ? tint
                : Color.clear,
                in:
                    Circle()
            )
            .background(
                .ultraThinMaterial,
                in:
                    Circle()
            )
        }
        .disabled(
            disabled
        )
        .accessibilityLabel(
            label
        )
    }
}
