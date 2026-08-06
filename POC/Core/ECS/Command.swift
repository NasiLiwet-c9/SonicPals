//
//  Command.swift
//  POC
//
//  Discrete, user-triggered actions coming in from SwiftUI / gestures.
//  These are handled immediately (they're one-shot, not per-frame
//  behaviour) by mutating Components on entities — see ECSWorld+*.swift.
//  Continuous, time-based behaviour (the mesh reveal/hide sequence)
//  is NOT a command; it's driven every frame by FPRevealSystem instead.
//

import CoreGraphics

enum ECSCommand {
    case place
    case sendWave
    case turn(Float)
    case toggleMesh
    case togglePoints
    case toggleView
    case clear
    case memoryWarning
    case dragBegan
    case dragChanged(CGPoint)
    case dragEnded
    case dragCancelled
}
