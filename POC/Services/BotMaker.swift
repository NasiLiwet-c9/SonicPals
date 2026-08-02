import RealityKit
import UIKit
import simd

@MainActor
final class BotMaker:
    BotMaking {

    func make() -> BotPart {
        let root = Entity()
        root.name = "boxBot"

        let bodyMat =
            SimpleMaterial(
                color: .lightGray,
                isMetallic: false
            )

        let sensorMat =
            SimpleMaterial(
                color: .systemCyan,
                isMetallic: false
            )

        let body = ModelEntity(
            mesh: .generateBox(
                size: SIMD3<Float>(
                    0.16,
                    0.10,
                    0.14
                )
            ),
            materials: [bodyMat]
        )

        body.position = SIMD3<Float>(
            0,
            0.05,
            0
        )

        root.addChild(body)

        let sensor = Entity()
        sensor.name = "sensor"

        sensor.position = SIMD3<Float>(
            0,
            0.06,
            -0.085
        )

        root.addChild(sensor)

        let disk = ModelEntity(
            mesh: .generateCylinder(
                height: 0.025,
                radius: 0.022
            ),
            materials: [sensorMat]
        )

        disk.orientation = simd_quatf(
            angle: Float.pi / 2,
            axis: SIMD3<Float>(
                1,
                0,
                0
            )
        )

        sensor.addChild(disk)

        return BotPart(
            root: root,
            sensor: sensor
        )
    }
}
