//
//  OnboardView.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import SwiftUI

struct OnboardPage: Identifiable {
    let id: Int

    let modelName: String

    let title: String
    let text: String
}

struct OnboardView: View {
    var buttonText = "Start"
    var onFinished: () -> Void = {}

    private let pages = [
        OnboardPage(
            id: 0,
            modelName: "Bat",
            title: "Bats listen for echoes",
            text:
                "Bats send very high-frequency sound. When the sound returns, the echo helps them understand what is around them."
        ),
        OnboardPage(
            id: 1,
            modelName: "Stylized_Tree",
            title: "Search the room",
            text:
                "Scan the floor, hide the virtual tree, then turn and move around the room to search for it."
        ),
        OnboardPage(
            id: 2,
            modelName: "Mango",
            title: "Find the mango",
            text:
                "Send ultrasonic waves, follow the haptic clues, and get close enough to reveal the tree and mango."
        )
    ]

    @State private var page = 0

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                TabView(
                    selection: $page
                ) {
                    ForEach(pages) { item in
                        OnboardCard(
                            page: item
                        )
                        .tag(item.id)
                    }
                }
                .tabViewStyle(
                    .page(
                        indexDisplayMode:
                            .never
                    )
                )
                .frame(
                    height: 560
                )

                dots

                Button(
                    action: advance
                ) {
                    Text(
                        page
                        == pages.count - 1
                        ? buttonText
                        : "Next"
                    )
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(
                        width: 150,
                        height: 52
                    )
                    .background(
                        .ultraThinMaterial,
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                Color.primary.opacity(
                                    0.12
                                ),
                                lineWidth: 1
                            )
                    )
                }

                Spacer()
            }
            .padding(
                .horizontal,
                24
            )
        }
        .preferredColorScheme(.light)
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(pages) { item in
                Circle()
                    .fill(
                        item.id == page
                        ? Color.primary
                        : Color(
                            .systemGray4
                        )
                    )
                    .frame(
                        width: 7,
                        height: 7
                    )
            }
        }
        .animation(
            .easeInOut(
                duration: 0.2
            ),
            value: page
        )
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation(
                .easeInOut(
                    duration: 0.3
                )
            ) {
                page += 1
            }
        } else {
            onFinished()
        }
    }
}

#Preview {
    OnboardView()
}
