import ARKit
import RealityKit
import UIKit
import simd

extension SceneCtrl {
    func spawn() {
        guard state.lidarOK,
              let ar else {
            setMsg(
                "LiDAR not available"
            )
            return
        }

        let point = CGPoint(
            x: ar.bounds.midX,
            y: ar.bounds.midY
        )

        guard let hit = place.hit(
            in: ar,
            at: point
        ) else {
            setMsg(
                "horizontal surface not found"
            )
            return
        }

        clearWave()

        bot?.removeFromParent()

        let part = botMaker.make()

        world.addChild(
            part.root
        )

        let position =
            hit.worldTransform.pos3

        part.root.setPosition(
            position,
            relativeTo: nil
        )

        yaw = camYaw(
            in: ar
        )

        let rotation = simd_quatf(
            angle: yaw,
            axis: SIMD3<Float>(
                0,
                1,
                0
            )
        )

        part.root.setOrientation(
            rotation,
            relativeTo: nil
        )

        bot = part.root
        sensor = part.sensor

        state.hasBot = true

        setMsg(
            "placed, drag to move"
        )
    }

    func turn(
        _ deg: Float
    ) {
        guard let bot else {
            return
        }

        clearWave()

        let rad =
            deg
            * Float.pi
            / 180

        yaw += rad

        let rotation = simd_quatf(
            angle: yaw,
            axis: SIMD3<Float>(
                0,
                1,
                0
            )
        )

        bot.setOrientation(
            rotation,
            relativeTo: nil
        )

        setMsg(
            "direction changed"
        )
    }

    func clear() {
        clearWave()

        bot?.removeFromParent()

        bot = nil
        sensor = nil

        state.hasBot = false

        setMsg(
            "robot removed"
        )
    }

    @objc
    func drag(
        _ pan: UIPanGestureRecognizer
    ) {
        guard let ar,
              let bot else {
            return
        }

        let validState =
            pan.state == .began
            || pan.state == .changed
            || pan.state == .ended

        guard validState else {
            return
        }

        let point = pan.location(
            in: ar
        )

        guard let hit = place.hit(
            in: ar,
            at: point
        ) else {
            return
        }

        clearWave()

        let position =
            hit.worldTransform.pos3

        bot.setPosition(
            position,
            relativeTo: nil
        )

        if pan.state == .ended {
            setMsg(
                "Box moved."
            )
        }
    }

    private func camYaw(
        in view: ARView
    ) -> Float {
        let matrix =
            view.cameraTransform.matrix

        var forward = SIMD3<Float>(
            -matrix.columns.2.x,
            0,
            -matrix.columns.2.z
        )

        if simd_length(forward) < 0.001 {
            forward = SIMD3<Float>(
                0,
                0,
                -1
            )
        } else {
            forward = simd_normalize(
                forward
            )
        }

        return atan2(
            -forward.x,
            -forward.z
        )
    }
}
