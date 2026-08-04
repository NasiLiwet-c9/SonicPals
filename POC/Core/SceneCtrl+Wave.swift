//
//  SceneCtrl+Wave.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Asaryun on 02/08/26.
//  Updated by Shanon Newcastle on 04/08/26.
//

import RealityKit

extension SceneCtrl {
    func sendWave() {
        guard let ar else {
            return
        }
        
        let start = state.viewMode == .first
        ? camStart(in: ar)
        : objStart()
        
        guard let start else {
            setMsg(
                "Place the object before sending a wave"
            )
            return
        }
        
        clearWave()
        
        let data = waveSim.run(
            in: ar,
            from: start
        )
        
        lastData = data
        
        if state.viewMode == .first {
            showFP(
                data,
                in: ar
            )
        } else {
            showTP(data)
        }
    }
    
    func toggleView() {
        clearWave()
        
        state.viewMode = state.viewMode == .first
        ? .third
        : .first
        
        state.pointsOn = false
        
        object?.isEnabled =
        state.viewMode == .third
        
        if state.viewMode == .first {
            if let ar {
                sess.showMesh(
                    false,
                    in: ar
                )
            }
            
            state.meshOn = false
            
            setMsg(
                "BAT VISION: tap Wave to reveal the room mesh"
            )
        } else if state.hasObject {
            setMsg(
                "THIRD POV: waves start from the object"
            )
        } else {
            setMsg(
                "THIRD POV: aim at a surface, then tap Place"
            )
        }
    }
}
