//
//  GIFImageView.swift
//  POC
//
//  Created by Asaryun on 13/08/26.
//

import ImageIO
import SwiftUI
import UIKit

private enum GIFLoader {
    /// GIFs live in `Assets.xcassets` as data sets. A catalog cannot
    /// *animate* a GIF — that is why this bridge exists — but it can
    /// perfectly well carry the bytes, which keeps them out of the
    /// bundle root and compiled into `Assets.car` with everything else.
    static func data(named name: String) -> Data? {
        NSDataAsset(name: name)?.data
    }

    static func animatedImage(named name: String) -> UIImage? {
        guard
            let data = data(named: name),
            let source = CGImageSourceCreateWithData(data as CFData, nil)
        else {
            return nil
        }

        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 0 else { return nil }

        var frames: [UIImage] = []
        var totalDuration: Double = 0

        for index in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }

            frames.append(UIImage(cgImage: cgImage))
            totalDuration += frameDuration(source: source, index: index)
        }

        guard !frames.isEmpty else { return nil }

        return UIImage.animatedImage(
            with: frames,
            duration: totalDuration
        )
    }

    private static func frameDuration(source: CGImageSource, index: Int) -> Double {
        let fallback = 0.1

        guard
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
            let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else {
            return fallback
        }

        let unclamped = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? Double
        let clamped = gifProperties[kCGImagePropertyGIFDelayTime] as? Double
        let duration = unclamped ?? clamped ?? fallback

        return duration < 0.02 ? fallback : duration
    }
}

private final class GIFUIImageView: UIImageView {
    override var intrinsicContentSize: CGSize {
        .zero
    }
}

private struct AnimatedGIF: UIViewRepresentable {
    let name: String
    let contentMode: UIView.ContentMode

    func makeUIView(context: Context) -> GIFUIImageView {
        let imageView = GIFUIImageView()

        imageView.contentMode = contentMode
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.image = GIFLoader.animatedImage(named: name)

        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        return imageView
    }

    func updateUIView(_ uiView: GIFUIImageView, context: Context) {
        uiView.contentMode = contentMode
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: GIFUIImageView,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width,
              let height = proposal.height else {
            return nil
        }

        return CGSize(width: width, height: height)
    }
}

struct GIFImageView: View {
    let name: String
    let contentMode: UIView.ContentMode

    init(
        name: String,
        contentMode: UIView.ContentMode = .scaleAspectFit
    ) {
        self.name = name
        self.contentMode = contentMode
    }

    var body: some View {
        if GIFLoader.data(named: name) != nil {
            AnimatedGIF(
                name: name,
                contentMode: contentMode
            )
        } else {
            Image(systemName: "cube.transparent")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
        }
    }
}
