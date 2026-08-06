//
//  ECSWorld+Placement.swift
//  POC
//
//  Replaces TP/SceneCtrl+Object.swift. Placement/turn/drag/clear all
//  read and write ObjectRootComponent on the placed entity instead of
//  instance vars on a controller.
//

import CoreGraphics
import RealityKit
import simd

extension ECSWorld {
    func place() {
        guard model.viewMode == .third else {
            setMsg("Switch to THIRD POV before placing the bat")
            return
        }

        var session = sessionEntity.components[SessionComponent.self]
            ?? SessionComponent()

        guard session.lidarOK, ar != nil else {
            setMsg("LiDAR not available")
            return
        }

        guard !session.isPlacing else {
            return
        }

        session.isPlacing = true
        sessionEntity.components[SessionComponent.self] = session

        setMsg("Loading Bat3…")

        Task { [weak self] in
            guard let self else {
                return
            }

            let ready = await self.objectMaker.prepare()

            var session = self.sessionEntity.components[SessionComponent.self]
                ?? SessionComponent()

            guard ready,
                  let part = self.objectMaker.make(),
                  let ar = self.ar else {
                session.isPlacing = false
                self.sessionEntity.components[SessionComponent.self] = session

                self.setMsg(
                    self.objectMaker.loadError
                        ?? "Bat3.usdz could not be loaded"
                )

                return
            }

            session.isPlacing = false
            self.sessionEntity.components[SessionComponent.self] = session

            self.spawn(part, in: ar)
        }
    }

    func turn(_ deg: Float) {
        guard model.viewMode == .third,
              let objectEntity,
              var objComp = objectEntity.components[ObjectRootComponent.self] else {
            return
        }

        clearWave()

        objComp.yaw += deg * Float.pi / 180
        objectEntity.components[ObjectRootComponent.self] = objComp

        objectEntity.setOrientation(
            simd_quatf(
                angle: objComp.yaw,
                axis: SIMD3<Float>(0, 1, 0)
            ),
            relativeTo: nil
        )

        setMsg("Bat direction changed")
    }

    func clear() {
        clearWave()

        objectEntity?.removeFromParent()
        objectEntity = nil
        waveStartEntity = nil

        model.hasObject = false

        setMsg("Bat removed")
    }

    func dragBegan() {
        guard model.viewMode == .third,
              let objectEntity else {
            return
        }

        clearWave()

        var objComp = objectEntity.components[ObjectRootComponent.self]
            ?? ObjectRootComponent()

        objComp.dragStart = objectEntity.position(relativeTo: nil)
        objectEntity.components[ObjectRootComponent.self] = objComp
    }

    func dragChanged(_ translation: CGPoint) {
        guard model.viewMode == .third,
              let ar,
              let objectEntity,
              let objComp = objectEntity.components[ObjectRootComponent.self],
              let dragStart = objComp.dragStart else {
            return
        }

        let position = tpSpawn.move(
            from: dragStart,
            translation: translation,
            in: ar
        )

        objectEntity.setPosition(position, relativeTo: nil)
    }

    func dragEnded() {
        guard let objectEntity,
              var objComp = objectEntity.components[ObjectRootComponent.self] else {
            return
        }

        objComp.dragStart = nil
        objectEntity.components[ObjectRootComponent.self] = objComp

        setMsg("Bat moved")
    }

    func dragCancelled() {
        guard let objectEntity,
              var objComp = objectEntity.components[ObjectRootComponent.self] else {
            return
        }

        objComp.dragStart = nil
        objectEntity.components[ObjectRootComponent.self] = objComp
    }

    private func spawn(_ part: ObjectPart, in view: ARView) {
        clearWave()

        objectEntity?.removeFromParent()

        let pose = tpSpawn.pose(in: view)

        anchor.addChild(part.root)

        part.root.setPosition(pose.position, relativeTo: nil)

        var objComp = ObjectRootComponent()
        objComp.yaw = pose.yaw
        part.root.components[ObjectRootComponent.self] = objComp

        part.waveStart.components[WaveStartComponent.self] = WaveStartComponent()

        part.root.setOrientation(
            simd_quatf(
                angle: objComp.yaw,
                axis: SIMD3<Float>(0, 1, 0)
            ),
            relativeTo: nil
        )

        objectEntity = part.root
        waveStartEntity = part.waveStart

        model.hasObject = true

        setMsg("Bat floating in front • tap Place to recenter")
    }
}
