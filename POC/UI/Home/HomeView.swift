//
//  HomeView.swift
//  POC
//
//  Created by Asaryun on 13/08/26.
//

import SwiftUI

struct HomeView: View {
    var mascotName = "fly"
    var speechText = "Your eyes might not be able to see in the dark, but my sonar can!"
    var primaryButtonText = "Let's Explore"
    var secondaryButtonText = "Select Mode"

    var onStart: () -> Void = {}
    var onSelectMode: () -> Void = {}

    var body: some View {
        ZStack {
            background

            VStack(spacing: 24) {
                Spacer()

                Model3DView(name: mascotName)
                    .frame(width: 160, height: 160)

                SpeechBubble(text: speechText)

                Spacer()

                VStack(spacing: 14) {
                    Button(action: onStart) {
                        Text(primaryButtonText.uppercased())
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.yellow, in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 32)

                    Button(action: onSelectMode) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(secondaryButtonText.uppercased())
                                .underline()
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.yellow)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 44)
            }
            .padding(.horizontal, 20)
        }
        .preferredColorScheme(.light)
    }

    //Background
    private var background: some View {
            ZStack {
                Color(red: 0.90, green: 0.89, blue: 0.98)
    
                Image("MainPageBackground")
                    .resizable()
                    .ignoresSafeArea()
            }
        
            //debug
            .onAppear {
                print("Asset found:", UIImage(named: "MainPageBackground") != nil)
            }
            .ignoresSafeArea()
        }
}

private struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold))
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .foregroundStyle(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: 300)
            .background(
                Color.white,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            )
    }
}

#Preview {
    HomeView()
}
