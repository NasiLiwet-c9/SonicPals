//
//  HapticSvc.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
//

import UIKit

@MainActor
final class HapticSvc {
    private let light =
        UIImpactFeedbackGenerator(
            style: .light
        )

    private let medium =
        UIImpactFeedbackGenerator(
            style: .medium
        )

    private let success =
        UINotificationFeedbackGenerator()

    init() {
        prepare()
    }

    func direction() {
        light.impactOccurred(
            intensity: 0.55
        )

        light.prepare()
    }

    func closer(strong: Bool) {
        if strong {
            medium.impactOccurred(
                intensity: 0.8
            )

            medium.prepare()
        } else {
            light.impactOccurred(
                intensity: 0.8
            )

            light.prepare()
        }
    }

    func found() {
        success.notificationOccurred(
            .success
        )

        success.prepare()
    }

    private func prepare() {
        light.prepare()
        medium.prepare()
        success.prepare()
    }
}
