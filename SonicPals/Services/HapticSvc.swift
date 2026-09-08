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
    static let shared = HapticSvc()

    let supported: Bool

    private let dir = UIImpactFeedbackGenerator(style: .rigid)

    private let near = UIImpactFeedbackGenerator(style: .heavy)

    private let strong = UIImpactFeedbackGenerator(style: .rigid)

    private let success = UINotificationFeedbackGenerator()

    init() {
        supported = CHHapticEngine
                .capabilitiesForHardware()
                .supportsHaptics

        prepare()
    }

    func direction() {
        guard supported else {
            return
        }

        dir.impactOccurred(intensity: 1.0)

        dir.prepare()
    }

    func closer(
        strong isStrong: Bool
    ) {
        guard supported else {
            return
        }

        if isStrong {
            strong.impactOccurred(intensity: 1.0)

            strong.prepare()

            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(55))

                guard let self else {
                    return
                }

                strong.impactOccurred(intensity: 1.0)

                strong.prepare()
            }
        } else {
            near.impactOccurred(intensity: 1.0)

            near.prepare()
        }
    }

    func found() {
        guard supported else {
            return
        }

        strong.impactOccurred(intensity: 1.0)

        success.notificationOccurred(.success)

        strong.prepare()
        success.prepare()

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(80))

            guard let self else {
                return
            }

            strong.impactOccurred(intensity: 1.0)

            strong.prepare()
        }
    }

    /// Two quick knocks, for biting the mango
    func munch() {
        guard supported else {
            return
        }

        strong.impactOccurred(intensity: 0.9)
        strong.prepare()

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(110))

            guard let self else {
                return
            }

            strong.impactOccurred(intensity: 0.7)
            success.notificationOccurred(.success)

            strong.prepare()
            success.prepare()
        }
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
