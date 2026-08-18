//
//  TargetReserveSvc.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import Foundation

@MainActor
final class TargetReserveSvc {
    private(set) var pose: TargetPose?
    private var lastCheckAt: TimeInterval = 0

    var ready: Bool { pose != nil }

    func canCheck(force: Bool = false) -> Bool {
        let now = Date().timeIntervalSinceReferenceDate

        if force {
            lastCheckAt = now
            return true
        }

        guard now - lastCheckAt >= TargetCfg.Preflight.checkInterval else { return false }
        lastCheckAt = now
        return true
    }

    func reserve(_ pose: TargetPose) {
        self.pose = pose
    }

    func take() -> TargetPose? {
        let value = pose
        pose = nil
        return value
    }

    func clearPose() {
        pose = nil
    }

    func clear() {
        pose = nil
        lastCheckAt = 0
    }
}
