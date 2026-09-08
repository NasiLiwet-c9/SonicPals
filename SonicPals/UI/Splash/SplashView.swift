//
//  SplashView.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//  Updated by Asaryun on 13/08/26
//

import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                Color(red: 0.07, green: 0.06, blue: 0.16)
                .ignoresSafeArea()

                GIFImageView(
                    name: "loadingscreen-animation",
                    contentMode: .scaleAspectFit
                )
                .frame(
                    width: UICfg.v(
                        UICfg.Load.bgW,
                        size
                    ),
                    height: UICfg.v(UICfg.Load.bgH, size)
                )
                .position(
                    x: size.width / 2,
                    y: size.height / 2 + UICfg.y(UICfg.Load.bgY, size)
                )
                .allowsHitTesting(false)

                progressBar
                    .frame(
                        width: UICfg.v(
                            UICfg.Load.barW,
                            size
                        ),
                        height: UICfg.v(UICfg.Load.barH, size)
                    )
                    .position(
                        x: size.width / 2,
                        y: UICfg.y(UICfg.Load.barY, size)
                    )
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .task {
            progress = 0

            withAnimation(
                .linear(duration: UICfg.Load.sec)
            ) {
                progress = 1
            }

            try? await Task.sleep(for: .seconds(UICfg.Load.sec))

            guard !Task.isCancelled else {
                return
            }

            onFinished()
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white)
                    .overlay {
                        Capsule()
                            .stroke(Color.indigo, lineWidth: 2)
                    }

                Capsule()
                    .fill(.yellow)
                    .frame(width: geo.size.width * progress)
                    .padding(2)
            }
        }
    }
}

#Preview("Loading") {
    SplashView {}
}
