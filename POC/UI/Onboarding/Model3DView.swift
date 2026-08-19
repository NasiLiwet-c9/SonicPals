//
//  Model3DView.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import SwiftUI

struct Model3DView: View {
    let name: String

    var body: some View {
        ZStack {
            // UIImage(named:) safely checks if the PNG exists in your Assets
            if let uiImage = UIImage(named: name) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                // Shows the transparent cube if you forgot to add the PNG to Assets
                Image(systemName: "cube.transparent")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
