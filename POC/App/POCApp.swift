//
//  POCApp.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import RealityKit
import SwiftUI

@main
struct POCApp: App {
    init() {
        SessComp.registerComponent()
        RevealComp.registerComponent()
        TraceComp.registerComponent()
        TargetComp.registerComponent()

        FPRevealSys.registerSystem()
        TargetSys.registerSystem()
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            RootView()
        }
    }
}
