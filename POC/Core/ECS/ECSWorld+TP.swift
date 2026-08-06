//
//  ECSWorld+TP.swift
//  POC
//
//  Replaces TP/SceneCtrl+TP.swift. TP drawing is synchronous/instant
//  (no multi-frame reveal), so unlike BAT VISION it doesn't need its
//  own System — it just builds an entity and tags it WaveVisualComponent
//  so clearWave() can find it generically.
//

import Foundation
import RealityKit
import simd

extension ECSWorld {
    func objStart() -> WaveStart? {
        guard let waveStartEntity else {
            return nil
        }

        return WaveStart(
            pos: waveStartEntity.convert(position: .zero, to: nil),
            forward: worldDir(SIMD3<Float>(0, 0, -1), from: waveStartEntity),
            right: worldDir(SIMD3<Float>(1, 0, 0), from: waveStartEntity),
            up: worldDir(SIMD3<Float>(0, 1, 0), from: waveStartEntity)
        )
    }

    func showTP(_ data: WaveData) {
        drawTP(data)
        showTPMsg(data)
    }

    func togglePoints() {
        guard model.viewMode == .third else {
            setMsg("BAT VISION keeps the scan rays hidden")
            return
        }

        guard let data = lastData else {
            return
        }

        model.pointsOn.toggle()
        drawTP(data)

        setMsg(
            model.pointsOn
                ? "GREEN = echo returned • RED = no clear echo"
                : "Showing the strongest result only"
        )
    }

    private func drawTP(_ data: WaveData) {
        visualEntity?.removeFromParent()

        let drawing = waveDraw.make(from: data, showAllPoints: model.pointsOn)
        drawing.components[WaveVisualComponent.self] = WaveVisualComponent(kind: .tp)

        anchor.addChild(drawing)

        visualEntity = drawing
        model.hasWave = true
    }

    private func showTPMsg(_ data: WaveData) {
        let setting = data.setting
        let pov = model.viewMode.title

        if let echo = data.nearestEcho,
           let time = data.echoMs {
            let distance = String(format: "%.2f m", Double(echo.distanceM))
            let delay = String(format: "%.1f ms", Double(time))
            let frequency = "\(Int(setting.startKHz))→\(Int(setting.endKHz)) kHz"
            let direction = dirText(data.strongestEcho?.sideDeg)

            setMsg(
                "\(pov) • ECHO RETURNED • \(frequency) • \(distance) • \(delay) • \(direction)"
            )
            return
        }

        if data.hitCount > 0 {
            setMsg("\(pov) • NO CLEAR ECHO • sound reflected away or became too weak")
            return
        }

        setMsg("\(pov) • no surface inside the wave area")
    }

    private func dirText(_ sideDeg: Float?) -> String {
        guard let sideDeg else {
            return "CENTER"
        }

        if sideDeg < -5 {
            return "LEFT"
        }

        if sideDeg > 5 {
            return "RIGHT"
        }

        return "CENTER"
    }

    private func worldDir(_ direction: SIMD3<Float>, from source: Entity) -> SIMD3<Float> {
        simd_normalize(source.convert(direction: direction, to: nil))
    }
}
