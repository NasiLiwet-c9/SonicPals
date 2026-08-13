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
    static func animatedImage(named name: String, withExtension ext: String = "gif") -> UIImage? {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: ext),
            let data = try? Data(contentsOf: url),
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

        return UIImage.animatedImage(with: frames, duration: totalDuration)
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

private struct AnimatedGIF: UIViewRepresentable {
    let name: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = GIFLoader.animatedImage(named: name)
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}
}

struct GIFImageView: View {
    let name: String

    var body: some View {
        if Bundle.main.url(forResource: name, withExtension: "gif") != nil {
            AnimatedGIF(name: name)
        } else {
            Image(systemName: "cube.transparent")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
        }
    }
}
