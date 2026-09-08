//
//  PingButton.swift
//  POC
//
//  Created by Shan Newcastle on 04/09/26.
//

import SwiftUI

/// A tap fires once, holding refires each time the cooldown clears
///
/// Driven by the press, not a `Button` action, which only lands on
/// release. The rule itself lives in `PingCooldown`
struct PingButton: View {
    let enabled: Bool
    let cooldown: Duration
    let onFire: () -> Void

    @State private var pressed = false
    @State private var ping: PingCooldown

    init(
        enabled: Bool,
        cooldown: Duration = .seconds(1),
        onFire: @escaping () -> Void
    ) {
        self.enabled = enabled
        self.cooldown = cooldown
        self.onFire = onFire

        _ping = State(wrappedValue: PingCooldown(cooldown: cooldown))
    }

    var body: some View {
        face
            .scaleEffect(pressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: pressed)
            .opacity(enabled ? 1 : 0.4)
            .contentShape(Circle())
            // minimumDuration is never reached, so `perform` never runs:
            // this is here purely for the press-down / press-up callbacks
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
                ping.coolingDown
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
                .scaledToFit()
                .frame(width: 108, height: 108)

            if ping.coolingDown {
                Circle()
                    .fill(.black.opacity(0.48))
                    .frame(width: 94, height: 94)

                Circle()
                    .trim(from: 0, to: ping.progress)
                    .stroke(
                        .white.opacity(0.92),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 96, height: 96)
                    .animation(
                        .linear(duration: cooldown.seconds),
                        value: ping.progress
                    )

                Image(systemName: "timer")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    /// Fires while the finger is down. `.task(id: pressed)` cancels this
    /// on release, which stops the repeat
    private func repeatWhileHeld() async {
        while !Task.isCancelled, pressed, enabled {
            // A press part-way through an earlier shot's cooldown waits
            // it out rather than being dropped
            fire()

            await ping.waitForCooldown()
        }
    }

    private func fire() {
        guard ping.fire(enabled: enabled) else { return }

        onFire()
    }
}
