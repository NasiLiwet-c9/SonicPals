//
//  TargetClearSvc.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import ARKit
import RealityKit
import simd

@MainActor
final class TargetClearSvc: TargetSpawnClearing {
    private let wall: any TargetWallChecking
    private let object: any TargetObjectChecking

    init() {
        wall = TargetWallSvc()
        object = TargetObjectSvc()
    }

    init(wall: any TargetWallChecking, object: any TargetObjectChecking) {
        self.wall = wall
        self.object = object
    }

    func clear(at pos: SIMD3<Float>, height: Float, session: ARSession, scene: Scene) -> Bool {
        if wall.blocked(at: pos, height: height, session: session) {
#if DEBUG
            print("[TARGET SPAWN] WALL REJECT")
#endif
            return false
        }

        if object.blocked(at: pos, height: height, scene: scene) {
#if DEBUG
            print("[TARGET SPAWN] OBJECT REJECT")
#endif
            return false
        }

        return true
    }
}
