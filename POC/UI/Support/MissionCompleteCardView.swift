//
//  MissionCompleteCardView.swift
//  POC
//
//  Created by Asaryun on 18/08/26.
//

import SwiftUI

struct MissionCompleteCardView: View {
    let onNext: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            ZStack(alignment: .bottomLeading) {
                Image("mission-completed-card")
                    .resizable()
                    .aspectRatio(452.0 / 385.0, contentMode: .fit)
                    .scaleEffect(1.3)
 
                Button(action: onNext) {
                    ZStack {
                        Image("btn-sort")
                            .resizable()
                            .aspectRatio(144.0 / 57.0, contentMode: .fit)
                            .frame(width: 130)

                        Text("Next")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.black)
                    }
                }
                .buttonStyle(.plain)
                .padding(.leading, 38)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60)   // nudges the group above dead-center
        }
    }
}

