//
//  AssetImageView.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import SwiftUI

/// An `Assets.xcassets` image, with a visible placeholder so a missing
/// one shows up instead of rendering nothing.
struct AssetImageView: View {
    let name: String

    var body: some View {
        if let image = UIImage(named: name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "cube.transparent")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
        }
    }
}
