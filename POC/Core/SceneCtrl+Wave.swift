import Foundation
import RealityKit

extension SceneCtrl {
    func pulse() {
        guard let ar,
              let sensor else {
            setMsg(
                "place robot first"
            )
            return
        }

        clearWave()

        let data = waveSim.run(
            in: ar,
            from: sensor
        )

        let waveEntity = waveDraw.make(
            from: data
        )

        world.addChild(
            waveEntity
        )

        wave = waveEntity

        showWaveMsg(
            data
        )
    }

    private func showWaveMsg(
        _ data: WaveData
    ) {
        if data.echoCount > 0,
           let time = data.echoMs {

            let text = String(
                format: "Hit: %d/%d rays | %.2f ms",
                data.echoCount,
                data.rayCount,
                Double(time)
            )

            setMsg(text)
            return
        }

        if data.hitCount > 0 {
            setMsg(
                "object hit, but no echo returned"
            )
            return
        }

        setMsg(
            "no object hit"
        )
    }
}
