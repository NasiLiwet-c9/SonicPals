//
//  MainView.swift
//  POC

//  Created by Shanon Newcastle on ??/??/??.
//  Updated by Asaryun on 02/08/26.
//
import SwiftUI

@MainActor
struct MainView: View {
    @StateObject private var vm: ARVM

    init() {
        _vm = StateObject(
            wrappedValue: ARVM()
        )
    }

    var body: some View {
        ZStack {
            ARViewBox(vm: vm)
                .ignoresSafeArea()
                .gesture(rotationGesture)

            crosshair

            VStack {
                status

                Spacer()

                HStack {
                    Spacer()
                    MeshToggleButton(vm: vm)
                }

                ControlsView(vm: vm)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }

    private var status: some View {
        Text(vm.state.msg)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var crosshair: some View {
        Image(systemName: "plus")
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(.white)
            .shadow(radius: 3)
            .allowsHitTesting(false)
    }

    // MARK: - Rotation gesture

    @GestureState private var rotationDelta: Angle = .zero

    private var rotationGesture: some Gesture {
        RotationGesture()
            .updating($rotationDelta) { value, state, _ in
                let delta = value - state
                state = value
//                Error printing dont mint it
//                print("rotation gesture fired, delta: \(delta.degrees), hasBot: \(vm.state.hasBot)")
                guard vm.state.hasBot else { return }
                vm.turn(Float(-delta.degrees))
            }
    }
}
