//
//  ARState.swift
//  POC
//
//  Created by Shanon Newcastle on 03/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

enum ViewMode: String {
    case first
    case third

    var title: String {
        rawValue.uppercased()
    }
}
