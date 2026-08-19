//
//  MangoCounterView.swift
//  POC
//
//  Created by James Richard Renaldo on 17/08/26.
//

import SwiftUI

struct MangoCounterView: View {
    let eatenCount: Int
    let target: Int

    var body: some View {
        HStack(spacing: 6) {
            Image("mango-miniicon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)

            Text("\(eatenCount)/\(target)")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
