//
//  SceneCtrl+TP.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//

import Foundation
import RealityKit
import simd

extension SceneCtrl {
    func objStart() -> WaveStart? {
        guard let waveStart else {
            return nil
        }
        
        return WaveStart(
            pos: waveStart.convert(
                position: .zero,
                to: nil
            ),
            forward: worldDir(
                SIMD3<Float>(0, 0, -1),
                from: waveStart
            ),
            right: worldDir(
                SIMD3<Float>(1, 0, 0),
                from: waveStart
            ),
            up: worldDir(
                SIMD3<Float>(0, 1, 0),
                from: waveStart
            )
        )
    }
    
    func showTP(
        _ data: WaveData
    ) {
        drawTP(data)
        showTPMsg(data)
    }
    
    func togglePoints() {
        guard state.viewMode == .third else {
            setMsg(
                "BAT VISION keeps the scan rays hidden"
            )
            return
        }
        
        guard let data = lastData else {
            return
        }
        
        state.pointsOn.toggle()
        drawTP(data)
        
        setMsg(
            state.pointsOn
            ? "GREEN = echo returned • RED = no clear echo"
            : "Showing the strongest result only"
        )
    }
    
    private func drawTP(
        _ data: WaveData
    ) {
        tpWave?.removeFromParent()
        
        let drawing = waveDraw.make(
            from: data,
            showAllPoints: state.pointsOn
        )
        
        world.addChild(drawing)
        
        tpWave = drawing
        state.hasWave = true
        push()
    }
    
    private func showTPMsg(
        _ data: WaveData
    ) {
        let setting = data.setting
        let pov = state.viewMode.title
        
        if let echo = data.nearestEcho,
           let time = data.echoMs {
            let distance = String(
                format: "%.2f m",
                Double(echo.distanceM)
            )
            
            let delay = String(
                format: "%.1f ms",
                Double(time)
            )
            
            let frequency =
            "\(Int(setting.startKHz))→\(Int(setting.endKHz)) kHz"
            
            let direction = dirText(
                data.strongestEcho?.sideDeg
            )
            
            setMsg(
                "\(pov) • ECHO RETURNED • \(frequency) • \(distance) • \(delay) • \(direction)"
            )
            return
        }
        
        if data.hitCount > 0 {
            setMsg(
                "\(pov) • NO CLEAR ECHO • sound reflected away or became too weak"
            )
            return
        }
        
        setMsg(
            "\(pov) • no surface inside the wave area"
        )
    }
    
    private func dirText(
        _ sideDeg: Float?
    ) -> String {
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
    
    private func worldDir(
        _ direction: SIMD3<Float>,
        from source: Entity
    ) -> SIMD3<Float> {
        simd_normalize(
            source.convert(
                direction: direction,
                to: nil
            )
        )
    }
}
