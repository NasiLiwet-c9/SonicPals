//
//  Components.swift
//  POC
//
//  RealityKit Components carrying the state that used to be scattered
//  as instance vars on SceneCtrl. Each piece of state now lives on the
//  entity it actually describes, instead of on one god object:
//
//   - SessionComponent      -> on the world anchor: session/mesh flags
//   - ObjectRootComponent   -> on the placed Bat3 root: yaw, drag state
//   - WaveStartComponent    -> marks the invisible wave-emission child
//   - FPRevealComponent     -> drives the BAT VISION mesh reveal/hide
//                              sequence; consumed by FPRevealSystem.
//

import RealityKit
import ARKit
import simd

/// Session/scene-reconstruction flags. Lives on the world anchor entity.
struct SessionComponent: Component {
    var lidarOK = false
    var meshOn = false
    var isPlacing = false
}

/// Marks the root entity of the placed Bat3 object and carries its
/// interaction state (yaw for rotation, drag anchor for panning).
struct ObjectRootComponent: Component {
    var yaw: Float = 0
    var dragStart: SIMD3<Float>?
}

/// Marker for the invisible child entity waves are emitted from
/// when in third-person (TP) mode.
struct WaveStartComponent: Component {}

/// Marker + payload for whichever wave-result entity is currently in
/// the scene (either the FP cone/mesh reveal, or the TP ray drawing),
/// used purely so `clearWave()` can find and remove it generically.
struct WaveVisualComponent: Component {
    enum Kind {
        case fp
        case tp
    }

    let kind: Kind
}

/// Drives the BAT VISION mesh-reveal animation over multiple frames.
/// Replaces the old Task/async-sleep chain in SceneCtrl+FPAnim with a
/// real per-frame RealityKit System (see FPRevealSystem.swift).
struct FPRevealComponent: Component {
    enum Stage {
        case waitingForMesh(attempt: Int, nextTryAt: TimeInterval)
        case revealing(index: Int, startedAt: TimeInterval)
        case holding(until: TimeInterval)
        case hiding(zoneIndex: Int, lastStepAt: TimeInterval)
        case empty(until: TimeInterval)
    }

    let data: WaveData
    let fpMesh: any FPMeshBuilding
    let view: ARView
    let root: Entity

    var layers: [FPMeshLayer] = []
    var stage: Stage = .waitingForMesh(attempt: 0, nextTryAt: 0)

    /// Called once, on the frame the reveal/hide sequence completes
    /// or is abandoned (root removed from scene). Lets ECSWorld sync
    /// AppModel (`hasWave = false`) without the System knowing about
    /// AppModel at all.
    var onFinished: (() -> Void)?
}
