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
                            dim ? 0.18 : 0.02
                        ),
                    location: 0
                ),
                .init(
                    color:
                        .black.opacity(
                            dim ? 0.40 : 0.06
                        ),
                    location: 0.58
                ),
                .init(
                    color:
                        .black.opacity(
                            dim ? 0.72 : 0.12
                        ),
                    location: 1
                )
            ],
            center: .center,
            startRadius: 40,
            endRadius: 760
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
