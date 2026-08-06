//
//  AppModel.swift
//  POC
//
//  Replaces the old ARState struct + SceneCtrl.onState callback.
//  This holds ONLY what SwiftUI needs to render — it is not where
//  domain state lives. Domain state (object transform/yaw, session
//  flags, in-flight wave animation, etc.) lives on RealityKit
//  Components attached to entities; ECSWorld mirrors the relevant
//  bits into this struct after each command so the UI can bind to it.
//

import Observation

@MainActor
@Observable
final class AppModel {
    var msg = "move cam to detect room"
    var lidarOK = false
    var hasObject = false
    var meshOn = false
    var hasWave = false
    var pointsOn = false
    var viewMode: ViewMode = .first

    var canWave: Bool {
        lidarOK && (viewMode == .first || hasObject)
    }
}
