//
//  OnboardingCard.swift
//  POC
//
//  Created by Asaryun on 07/08/26.
//

import Foundation
import SwiftUI

struct OnboardingCard: View {
    let page: OnboardingPageData

    var body: some View {
        VStack(spacing: 18) {
            Model3DPreview(resourceName: page.modelName)
                .frame(height: 220)

            VStack(spacing: 10) {
                Text(page.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.primary.opacity(0.55), lineWidth: 1.2)
        )
        .padding(.horizontal, 4)
    }
}
