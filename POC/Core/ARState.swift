//
//  ARState.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 03/08/26.
//

enum ViewMode: String {
    case first
    case third
    
    var title: String {
        rawValue.uppercased()
    }
}

struct ARState: Equatable {
    var msg = "move cam to detect room"
    var lidarOK = false
    var hasObject = false
    var meshOn = false
    var hasWave = false
    var pointsOn = false
    var viewMode: ViewMode = .first
    
    var canWave: Bool {
        lidarOK && (viewMode == .first || hasObject)
    }
}
