//
//  MainView.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Asaryun on 02/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

import Foundation
import SwiftUI
import UIKit

@MainActor
struct MainView: View {
    @State
    private var world = ECSWorld()

    @GestureState
    private var rotationDelta: Angle = .zero

    var body: some View {
        ZStack {
            ARViewBox(world: world)
                .ignoresSafeArea()
                .simultaneousGesture(rotationGesture)

            FPShade(mode: world.model.viewMode)

            crosshair

            VStack {
                status

                Spacer()

//                ToggleBar(world: world)
                ControlsView(world: world)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
        .task {
            for await _ in
                NotificationCenter.default
                    .notifications(named: UIApplication.didReceiveMemoryWarningNotification) {
                world.perform(.memoryWarning)
            }
        }
    }

    private var status: some View {
        Text(world.model.msg)
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

    private var rotationGesture: some Gesture {
        RotationGesture()
            .updating($rotationDelta) { value, state, _ in
                let delta = value - state
                state = value

                guard
                    world.model.viewMode == .third,
                    world.model.hasObject
                else {
                    return
                }

                world.perform(.turn(Float(-delta.degrees)))
            }
    }
}
