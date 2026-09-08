//
//  HUDView+Overlays.swift
//  SonicPals
//
//  Created by Shan Newcastle on 08/09/26.
//

import SwiftUI

/// The full-screen pieces the HUD draws behind its controls
extension HUDView {
    var eatAnimation: some View {
        GeometryReader { geo in
            let size = geo.size
            let w = UICfg.v(UICfg.Eat.gifW, size)

            let h = w * (882.0 / 413.0)

            GIFImageView(
                name: "eat-animation",
                contentMode: .scaleAspectFit
            )
            .frame(width: w, height: h)
            .position(
                x: size.width / 2,
                y: size.height / 2 + UICfg.y(UICfg.Eat.gifY, size)
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    var scanTransition: some View {
        GeometryReader { geo in
            let size = geo.size
            let w = UICfg.v(UICfg.Trans.gifW, size)

            let h = w * (874.0 / 404.0)

            ZStack {
                GIFImageView(
                    name: "light-to-dark-transition",
                    contentMode: .scaleAspectFit
                )
                .frame(width: w, height: h)
                .position(
                    x: size.width / 2,
                    y: size.height / 2 + UICfg.y(UICfg.Trans.gifY, size)
                )

                Color.black
                    .opacity(world.model.missionDark ? UICfg.Trans.dim : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    func reticle(
        _ scale: CGFloat
    ) -> some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.45), lineWidth: 1)
                .frame(width: 82 * scale, height: 82 * scale)

            Circle()
                .stroke(.white.opacity(0.35), lineWidth: 1)
                .frame(width: 40 * scale, height: 40 * scale)

            Rectangle()
                .fill(.white.opacity(0.45))
                .frame(width: 1, height: 94 * scale)

            Rectangle()
                .fill(.white.opacity(0.45))
                .frame(width: 94 * scale, height: 1)

            Circle()
                .fill(.white)
                .frame(width: 5 * scale, height: 5 * scale)

            if world.model.hudStage == .scanning {
                Text(
                    "\(Int((world.model.scanProgress * 100).rounded()))%"
                )
                .font(
                    .system(
                        size: UICfg.Scan.pctTxt * scale,
                        weight: .heavy
                    )
                )
                .foregroundStyle(.white)
                .padding(.horizontal, UICfg.Scan.pctPadX * scale)
                .padding(.vertical, UICfg.Scan.pctPadY * scale)
                .background(
                    Color.black
                        .opacity(
                            UICfg.Scan.pctBg
                        ),
                    in: Capsule()
                )
                .shadow(color: .black.opacity(0.5), radius: 3)
                .offset(y: UICfg.Scan.pctY * scale)

                scanTurn(scale)
            }

        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    func scanTurn(
        _ scale: CGFloat
    ) -> some View {
        switch world.model.scanTurn {
        case .left:
            HStack(spacing: 0) {
                Image(systemName: "chevron.left")

                Image(systemName: "chevron.left")
            }
            .font(
                .system(
                    size: UICfg.Scan.arrTxt * scale,
                    weight: .heavy
                )
            )
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.55), radius: 2)
            .offset(x: -UICfg.Scan.arrX * scale)

        case .right:
            HStack(spacing: 0) {
                Image(systemName: "chevron.right")

                Image(systemName: "chevron.right")
            }
            .font(
                .system(
                    size: UICfg.Scan.arrTxt * scale,
                    weight: .heavy
                )
            )
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.55), radius: 2)
            .offset(x: UICfg.Scan.arrX * scale)

        case .none:
            EmptyView()
        }
    }
}
