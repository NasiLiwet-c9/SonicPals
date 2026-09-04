//
//  PingButton.swift
//  POC
//
//  Created by Shan Newcastle on 04/09/26.
//

import SwiftUI

/// The sonar button. A tap fires one ping; holding refires each time the
/// cooldown clears, never faster.
///
/// Driven by the press, not a `Button` action, which only lands on
/// release. Assistive activation has no press, so it gets its own action.
struct PingButton: View {
    let enabled: Bool
    let cooldown: Duration
    let onFire: () -> Void

    @State private var coolingDown = false
    @State private var cooldownProgress: CGFloat = 0
    @State private var pressed = false

    /// The repeat awaits this rather than sleeping the same duration
    /// alongside it, which would race. Not a child of the press task:
    /// letting go must not cut a cooldown short.
    @State private var cooldownTask: Task<Void, Never>?

    init(
        enabled: Bool,
        cooldown: Duration = .seconds(1),
        onFire: @escaping () -> Void
    ) {
        self.enabled = enabled
        self.cooldown = cooldown
        self.onFire = onFire
    }

    var body: some View {
        face
            .scaleEffect(pressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: pressed)
            .opacity(enabled ? 1 : 0.4)
            .contentShape(Circle())
            // minimumDuration is never reached, so `perform` never runs:
            // this is here purely for the press-down / press-up callbacks.
            .onLongPressGesture(
                minimumDuration: .infinity,
                maximumDistance: 40,
                perform: {},
                onPressingChanged: { isPressing in
                    pressed = enabled && isPressing
                }
            )
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(
                coolingDown
                    ? "Ultrasonic wave recharging"
                    : "Send ultrasonic wave"
            )
            .accessibilityHint("Touch and hold to keep pinging")
            .accessibilityAction {
                fire()
            }
            .task(id: pressed) {
                guard pressed else { return }

                await repeatWhileHeld()
            }
    }

    private var face: some View {
        ZStack {
            Image("ping-btn")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 108, height: 108)

            if coolingDown {
                Circle()
                    .fill(.black.opacity(0.48))
                    .frame(width: 94, height: 94)

                Circle()
                    .trim(from: 0, to: cooldownProgress)
                    .stroke(
                        .white.opacity(0.92),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 96, height: 96)

                Image(systemName: "timer")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    /// Fires while the finger is down. `.task(id: pressed)` cancels this
    /// on release, which stops the repeat.
    private func repeatWhileHeld() async {
        while !Task.isCancelled, pressed, enabled {
            // Pressing part-way through an earlier shot's cooldown waits
            // it out rather than being dropped.
            if !coolingDown {
                fire()
            }

            guard let cooldownTask else { return }

            await cooldownTask.value
        }
    }

    private func fire() {
        guard enabled, !coolingDown else { return }

        onFire()

        coolingDown = true
        cooldownProgress = 1

        cooldownTask = Task { @MainActor in
            await Task.yield()

            withAnimation(.linear(duration: cooldown.seconds)) {
                cooldownProgress = 0
            }

            try? await Task.sleep(for: cooldown)

            coolingDown = false
            cooldownProgress = 0
        }
    }
}

private extension Duration {
    var seconds: Double {
        Double(components.seconds)
            + (Double(components.attoseconds) / 1e18)
    }
}
