//
//  ECSWorld+Wave.swift
//  POC
//
//  Replaces Core/SceneCtrl+Wave.swift.
//

import RealityKit

extension ECSWorld {
    func sendWave() {
        guard let ar else {
            return
        }

        let start = model.viewMode == .first
            ? camStart(in: ar)
            : objStart()

        guard let start else {
            setMsg("Place the object before sending a wave")
            return
        }

        clearWave()

        let data = waveSim.run(in: ar, from: start)
        lastData = data

        if model.viewMode == .first {
            showFP(data, in: ar)
        } else {
            showTP(data)
        }
    }

    func toggleView() {
        clearWave()

        model.viewMode = model.viewMode == .first ? .third : .first
        model.pointsOn = false

        objectEntity?.isEnabled = model.viewMode == .third

        if model.viewMode == .first {
            if let ar {
                sess.showMesh(false, in: ar)
            }

            var session = sessionEntity.components[SessionComponent.self]
                ?? SessionComponent()

            session.meshOn = false
            sessionEntity.components[SessionComponent.self] = session
            model.meshOn = false

            setMsg("BAT VISION: tap Wave to reveal the room mesh")
        } else if model.hasObject {
            setMsg("THIRD POV: waves start from the object")
        } else {
            setMsg("THIRD POV: aim at a surface, then tap Place")
        }
    }
}
