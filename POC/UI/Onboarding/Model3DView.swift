//
//  Model3DView.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import QuickLookThumbnailing
import SwiftUI
import UIKit

struct Model3DView: View {
    let name: String

    @Environment(\.displayScale) private var displayScale

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if failed {
                Image(systemName: "cube.transparent")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        }
        .task(id: name) {
            await load()
        }
    }

    @MainActor
    private func load() async {
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: "usdz"
        ) else {
            failed = true
            return
        }

        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(
                width: 700,
                height: 700
            ),
            scale: displayScale,
            representationTypes: .thumbnail
        )

        do {
            let result = try await QLThumbnailGenerator.shared
                .generateBestRepresentation(
                    for: request
                )

            image = result.uiImage
            failed = false
        } catch {
            failed = true
        }
    }
}
