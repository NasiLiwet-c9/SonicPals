//
//  MeshView.swift
//  POC
//
//  Created by Asaryun on 02/08/26.
//
import SwiftUI

struct MeshToggleButton: View {
    @ObservedObject var vm: ARVM

    var body: some View {
        Button {
            vm.toggleMesh()
        } label: {
            Image(systemName: vm.state.meshOn ? "eye" : "eye.slash")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(vm.state.meshOn ? .white : .blue)
                .frame(width: 44, height: 44)
                .background(
                    vm.state.meshOn ? .blue : Color.clear,
                    in: Circle()
                )
                .background(.ultraThinMaterial, in: Circle())
        }
        .disabled(!vm.state.lidarOK)
        .accessibilityLabel(vm.state.meshOn ? "Hide mesh" : "Show mesh")
    }
}

