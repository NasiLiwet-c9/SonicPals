//
//  SceneCtrl+Wave.swift
//  POC
//
//  Created by Shanon Newcastle on ??/??/??.
//  Updated by Asaryun on 02/08/26.
//
import Foundation
import RealityKit

extension SceneCtrl {
    func pulse() {
        guard let ar,
              let sensor else {
            setMsg("place robot first")
            return
        }

        clearWave()

        let data = waveSim.run(in: ar, from: sensor)
        let waveEntity = waveDraw.make(from: data)

        world.addChild(waveEntity)
        wave = waveEntity

        showWaveMsg(data)

        // Auto-clear the wave visual after it's had time to read
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s, tune to taste
            guard let self, self.wave === waveEntity else { return }
            self.clearWave()
        }
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
