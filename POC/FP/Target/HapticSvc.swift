//
//  HapticSvc.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import CoreHaptics
import UIKit

@MainActor
final class HapticSvc {
    let supported: Bool

    private let dir =
        UIImpactFeedbackGenerator(
            style: .light
        )

    private let near =
        UIImpactFeedbackGenerator(
            style: .medium
        )

    private let strong =
        UIImpactFeedbackGenerator(
            style: .heavy
        )

    private let success =
        UINotificationFeedbackGenerator()

    init() {
        supported =
            CHHapticEngine
                .capabilitiesForHardware()
                .supportsHaptics

        prepare()
    }

    func direction() {
        guard supported else {
            return
        }

        dir.impactOccurred(
            intensity: 0.65
        )

        dir.prepare()
    }

    func closer(strong isStrong: Bool) {
        guard supported else {
            return
        }

        if isStrong {
            strong.impactOccurred(
                intensity: 0.85
            )

            strong.prepare()
        } else {
            near.impactOccurred(
                intensity: 0.70
            )

            near.prepare()
        }
    }

    func found() {
        guard supported else {
            return
        }

        success.notificationOccurred(
            .success
        )

        success.prepare()
    }

    private func prepare() {
        guard supported else {
            return
        }

        dir.prepare()
        near.prepare()
        strong.prepare()
        success.prepare()
    }
}
