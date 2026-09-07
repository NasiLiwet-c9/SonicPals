//
//  CreditsView.swift
//  POC
//
//  Created by Shan Newcastle on 04/09/26.
//

import SwiftUI

/// The team, as a quiet footer. Menu screens only
struct CreditsView: View {
    let uiScale: CGFloat

    private let credits: [(role: String, names: String)] = [
        (
            "Art Direction & World Building",
            "Rio Ardi Ferdian, Michelle Gravielle Benedicta Roring"
        ),
        (
            "Technical Direction & AR Space",
            "Shanon Giuly Istanto, James Richard Renaldo, Jayvin Tiya Silo"
        )
    ]

    var body: some View {
        VStack(spacing: UICfg.Credits.gap * uiScale) {
            ForEach(credits, id: \.role) { credit in
                Text("\(credit.role): \(credit.names)")
                    .font(
                        .system(
                            size: UICfg.Credits.txt * uiScale,
                            weight: .medium
                        )
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(UICfg.Credits.alpha))
                    // No plate, so the text carries its own contrast
                    .shadow(color: .black.opacity(0.85), radius: 1)
                    .shadow(color: .black.opacity(0.55), radius: 4)
            }
        }
        .padding(.horizontal, UICfg.Credits.padX * uiScale)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }
}
