//
//  FPShade.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import SwiftUI

struct FPShade: View {
    let dim: Bool

    var body: some View {
        RadialGradient(
            stops: [
                .init(
                    color:
                        .black.opacity(
                            dim
                            ? 0.62
                            : 0.10
                        ),
                    location: 0
                ),

                .init(
                    color:
                        .black.opacity(
                            dim
                            ? 0.84
                            : 0.20
                        ),
                    location: 0.58
                ),

                .init(
                    color:
                        .black.opacity(
                            dim
                            ? 0.96
                            : 0.32
                        ),
                    location: 1
                )
            ],
            center: .center,
            startRadius: 34,
            endRadius: 760
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
