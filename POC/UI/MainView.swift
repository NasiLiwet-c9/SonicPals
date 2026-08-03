//
//  MainView.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Asaryun on 02/08/26.
//  Updated by Shanon Newcastle on 03/08/26.
//

import SwiftUI

@MainActor
struct MainView:
    View {
    
    @State
    private var vm =
    ARVM()
    
    @GestureState
    private var rotationDelta:
    Angle = .zero
    
    var body:
    some View {
        ZStack {
            ARViewBox(
                vm:
                    vm
            )
            .ignoresSafeArea()
            .simultaneousGesture(
                rotationGesture
            )
            
            crosshair
            
            VStack {
                status
                
                Spacer()
                
                ToggleBar(
                    vm:
                        vm
                )
                
                ControlsView(
                    vm:
                        vm
                )
            }
            .padding()
        }
        .preferredColorScheme(
            .dark
        )
    }
    
    private var status:
    some View {
        Text(
            vm.state.msg
        )
        .font(
            .subheadline
        )
        .multilineTextAlignment(
            .center
        )
        .padding(
            10
        )
        .frame(
            maxWidth:
                    .infinity
        )
        .background(
            Color.black
                .opacity(
                    0.6
                )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    10
            )
        )
    }
    
    private var crosshair:
    some View {
        Image(
            systemName:
                "plus"
        )
        .font(
            .system(
                size:
                    26,
                weight:
                        .bold
            )
        )
        .foregroundStyle(
            .white
        )
        .shadow(
            radius:
                3
        )
        .allowsHitTesting(
            false
        )
    }
    
    private var rotationGesture:
    some Gesture {
        RotationGesture()
            .updating(
                $rotationDelta
            ) {
                value,
                state,
                _ in
                
                let delta =
                value
                - state
                
                state =
                value
                
                guard
                    vm.state.viewMode == .third,
                    vm.state.hasObject
                else {
                    return
                }
                
                vm.turn(
                    Float(
                        -delta.degrees
                    )
                )
            }
    }
}
