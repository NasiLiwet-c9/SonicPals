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
        FPScanComp.registerComponent()

        FPRevealSys.registerSystem()
        TargetSys.registerSystem()
        MangoEatSys.registerSystem()
        FPScanSys.registerSystem()
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            RootView()
        }
    }
}
