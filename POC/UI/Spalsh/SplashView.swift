//
//  SplashView.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//  Upodated by Asaryun on 13/08/26

import SwiftUI

struct SplashView: View {
    var mascotGifName = "for loading page"
    var guidanceText = "jangan lupa scan seluruh ruangan dulu ya sebelum main...."

    let onFinished: () -> Void

    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            background

            VStack {
                Spacer()

                GIFImageView(name: mascotGifName)
                    .frame(width: 150, height: 150)

                Spacer()
                    .frame(height: 52)

                progressBar
                    .frame(height: 14)
                    .padding(.horizontal, 40)

                Spacer()

                Text(guidanceText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            // Replace with real readiness checks (asset preload, LiDAR/session
            // warm-up, etc.) and call onFinished() once actually ready.
            withAnimation(.easeInOut(duration: 3.0)) {
                progress = 1
            }

            try? await Task.sleep(for: .seconds(1.8))

            onFinished()
        }
    }

    private var background: some View {
        Color(red: 0.09, green: 0.08, blue: 0.20)
            .ignoresSafeArea()
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white)
                    .overlay(
                        Capsule()
                            .stroke(Color.indigo, lineWidth: 2)
                    )

                Capsule()
                    .fill(Color.yellow)
                    .frame(width: proxy.size.width * progress)
                    .padding(2)
            }
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
