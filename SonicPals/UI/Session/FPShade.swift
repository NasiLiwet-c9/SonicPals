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
                    color: .black.opacity(
                        dim ? UICfg.Shade.darkMid : UICfg.Shade.liteMid
                    ),
                    location: 0
                ),
                .init(
                    color: .black.opacity(
                        dim ? UICfg.Shade.darkHalf : UICfg.Shade.liteHalf
                    ),
                    location: 0.58
                ),
                .init(
                    color: .black.opacity(
                        dim ? UICfg.Shade.darkEdge : UICfg.Shade.liteEdge
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
