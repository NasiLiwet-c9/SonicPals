//
//  MapView.swift
//  POC
//
//  Created by Shan Newcastle on 19/08/26.
//

import SwiftUI

struct MapView: View {
    let onBack: () -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                GIFImageView(
                    name: "bg-map-animation",
                    contentMode: .scaleAspectFill
                )
                .frame(
                    width: geo.size.width,
                    height: geo.size.height
                )
                .clipped()
                .ignoresSafeArea()
                .allowsHitTesting(false)

                GIFImageView(name: "flying-animation-mascot")
                    .frame(width: 145, height: 145)
                    .position(
                        x: geo.size.width * 0.38,
                        y: geo.size.height * 0.22
                    )
                    .allowsHitTesting(false)

                VStack {
                    HStack {
                        Button(action: onBack) {
                            Image("arrow-left")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 51, height: 48)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Back")

                        Spacer()
                    }

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MapView {}
}
