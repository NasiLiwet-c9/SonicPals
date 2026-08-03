//
//  ARViewBox.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Shanon Newcastle on 03/08/26.
//

import RealityKit
import SwiftUI

@MainActor
struct ARViewBox:
    UIViewRepresentable {
    
    let vm:
    ARVM
    
    func makeUIView(
        context: Context
    ) -> ARView {
        let view =
        ARView(
            frame:
                    .zero,
            cameraMode:
                    .ar,
            automaticallyConfigureSession:
                false
        )
        
        vm.setup(
            view
        )
        
        return view
    }
    
    func updateUIView(
        _ uiView: ARView,
        context: Context
    ) {
    }
}
