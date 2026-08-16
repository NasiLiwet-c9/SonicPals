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
    var dialogueLines: [String] = [
        "Hi.... i'm Battiw",
        "I'm hungry, help me find something to eat tonight...!"
    ]
    var primaryButtonText = "Fly and Find"
    var onStart: () -> Void = {}
    var onSelectMode: () -> Void = {}

    var body: some View {
        ZStack {
            background

            VStack {
                Spacer()

                DialogueBubbleView(lines: dialogueLines, mascotName: mascotName)
                
//                Spacer()

                VStack(spacing: 14) {
                    Button(action: onStart) {
                        Text(primaryButtonText.uppercased())
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: 200)
                            .frame(height: 56)
                            .background(Color.yellow, in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 32)
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 300)
            }
            .padding(.horizontal, 20)
        }
        .preferredColorScheme(.light)
    }

    //Background
    private var background: some View {
            ZStack {
                Image("Onboarding full")
                    .ignoresSafeArea()
            }
            //debug
//            .onAppear {
//                print("Asset found:", UIImage(named: "Onboarding full") != nil)
//            }
            .ignoresSafeArea()
        }
}

#Preview {
    HomeView()
}
