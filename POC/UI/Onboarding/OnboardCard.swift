//
//  OnboardCard.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import SwiftUI

struct OnboardCard: View {
    let page: OnboardPage

    var body: some View {
        VStack(spacing: 18) {
            AssetImageView(
                name: page.modelName
            )
            .frame(
                height: 240
            )

            Text(page.title)
                .font(
                    .title2
                    .weight(.bold)
                )
                .multilineTextAlignment(
                    .center
                )

            Text(page.text)
                .font(.body)
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
                )
                .lineSpacing(3)

            Spacer(
                minLength: 0
            )
        }
        .padding(24)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .fill(
                Color(
                    .secondarySystemBackground
                )
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .stroke(
                Color.primary.opacity(
                    0.12
                ),
                lineWidth: 1
            )
        )
    }
}
