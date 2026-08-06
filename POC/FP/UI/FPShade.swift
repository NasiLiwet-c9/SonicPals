//
//  FPShade.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

import SwiftUI

struct FPShade: View {
    let mode: ViewMode
    
    var body: some View {
        if mode == .first {
            RadialGradient(
                stops: [
                    .init(
                        color:
                            Color.black
                            .opacity(0.16),
                        location: 0
                    ),
                    .init(
                        color:
                            Color.black
                            .opacity(0.27),
                        location: 0.52
                    ),
                    .init(
                        color:
                            Color.black
                            .opacity(0.48),
                        location: 1
                    )
                ],
                center: .center,
                startRadius: 60,
                endRadius: 720
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}
