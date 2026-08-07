//
//  OnboardingView.swift
//  POC
//
//  Created by James Richard Renaldo on 07/08/26.
//

import SwiftUI
struct OnboardingPageData: Identifiable {
    let id: Int
    let modelName: String
    let title: String
    let subtitle: String
}

struct OnboardingView: View {
    /// Called when the user taps the button on the last page.
    var onFinished: () -> Void = {}

    private let pages: [OnboardingPageData] = [
        OnboardingPageData(
            id: 0,
            modelName: "Bat",
            title: "Lorem Ipsum Dolor sit",
            subtitle: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since 1966, when designers at Letraset and James Mosley,"
        ),
        OnboardingPageData(
            id: 1,
            modelName: "Stylized_Tree",
            title: "Lorem Ipsum Dolor sit",
            subtitle: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since 1966, when designers at Letraset and James Mosley,"
        ),
        OnboardingPageData(
            id: 2,
            modelName: "Mango",
            title: "Lorem Ipsum Dolor sit",
            subtitle: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since 1966, when designers at Letraset and James Mosley,"
        )
    ]

    @State private var page = 0

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                TabView(selection: $page) {
                    ForEach(pages) { pageData in
                        OnboardingCard(page: pageData)
                            .tag(pageData.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 560)

                pageDots

                startButton

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.light)
        .onAppear {
            // TEMP DEBUG — remove once the missing .usdz files are sorted out.
            let names = ["Bat3", "Bat", "Bat_Dark_Balloon_Monster", "Tasty_Green_Apple", "Mango", "Mango-2", "Stylized_Tree"]

            for name in names {
                let url = Bundle.main.url(forResource: name, withExtension: "usdz")
                print("\(name): \(url?.lastPathComponent ?? "NOT FOUND")")
            }
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages) { pageData in
                Circle()
                    .fill(pageData.id == page ? Color.primary : Color(.systemGray4))
                    .frame(width: 7, height: 7)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: page)
    }

    private var startButton: some View {
        Button(action: advance) {
            Text("Start")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 150, height: 52)
                .glassEffect()
        }
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                page += 1
            }
        } else {
            onFinished()
        }
    }
}


#Preview {
    OnboardingView()
}
