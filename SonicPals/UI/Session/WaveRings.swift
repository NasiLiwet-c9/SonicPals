//
//  WaveRings.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//  Updated by Asaryun 13/08/26

import SwiftUI

struct WaveRings: View {
    let seq: Int

    @State private var pulse = false
    @State private var show = false

    private let violet = Color(red: 0.58, green: 0.49, blue: 1)

    var body: some View {
        GeometryReader { proxy in
            if show {
                ZStack {
                    ForEach(
                        0..<3,
                        id: \.self
                    ) { index in
                        Circle()
                            .stroke(
                                violet.opacity(
                                    0.42 - (Double(index) * 0.10)
                                ),
                                lineWidth: 1.8
                            )
                            .frame(width: 116, height: 116)
                            .scaleEffect(pulse ? (3.2 + (CGFloat(index) * 0.55)) : 0.78)
                            .opacity(pulse ? 0 : (0.75 - (Double(index) * 0.16)))
                            .animation(
                                .easeOut(duration: 0.9)
                                    .delay(Double(index) * 0.12),
                                value: pulse
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .position(
                    x: proxy.size.width / 2,
                    y: proxy.size.height * 0.516
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .task(id: seq) {
            guard seq > 0 else {
                return
            }

            show = true
            pulse = false

            // One turn of the run loop so the "collapsed" state is drawn
            // before the expansion animates out from it
            await Task.yield()
            pulse = true

            try? await Task.sleep(for: .milliseconds(1250))

            guard !Task.isCancelled else {
                return
            }

            show = false
            pulse = false
        }
    }
}
