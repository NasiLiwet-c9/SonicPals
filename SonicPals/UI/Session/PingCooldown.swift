//
//  PingCooldown.swift
//  POC
//
//  Created by Shan Newcastle on 06/09/26.
//

import Foundation
import Observation

/// A tap fires once, holding refires each time the cooldown clears
///
/// Split from `PingButton`, whose `@State` a test cannot reach
@MainActor
@Observable
final class PingCooldown {
    private(set) var coolingDown = false

    /// 1 on firing, winding down to 0
    private(set) var progress: CGFloat = 0

    @ObservationIgnored private var task: Task<Void, Never>?

    let cooldown: Duration

    init(cooldown: Duration = .seconds(1)) {
        self.cooldown = cooldown
    }

    func canFire(enabled: Bool) -> Bool {
        enabled && !coolingDown
    }

    /// Returns whether it actually fired
    @discardableResult
    func fire(enabled: Bool) -> Bool {
        guard canFire(enabled: enabled) else { return false }

        coolingDown = true
        progress = 1

        task = Task { @MainActor [weak self] in
            guard let self else { return }

            try? await Task.sleep(for: cooldown)

            coolingDown = false
            progress = 0
        }

        return true
    }

    /// Waits out the shot in flight, if any
    func waitForCooldown() async {
        await task?.value
    }

    /// For teardown, not for skipping a cooldown
    func reset() {
        task?.cancel()
        task = nil
        coolingDown = false
        progress = 0
    }
}

extension Duration {
    var seconds: Double {
        Double(components.seconds)
            + (Double(components.attoseconds) / 1e18)
    }
}
