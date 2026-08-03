//
//  SceneCtrl+Wave.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Asaryun on 02/08/26.
//  Updated by Shanon Newcastle on 03/08/26.
//

import Foundation
import RealityKit
import simd

extension SceneCtrl {
    func sendWave() {
        guard let ar else {
            return
        }
        
        guard let start =
                makeStart(
                    in: ar
                ) else {
            setMsg(
                "Place the object before sending a wave"
            )
            return
        }
        
        if state.viewMode == .first {
            pulseFX.emit(
                from: start,
                into: world
            )
        }
        
        if state.viewMode == .third {
            beamFX.emit(
                from: start,
                into: world,
                in: ar
            )
        }
        
        clearWave()
        
        let data =
        waveSim.run(
            in: ar,
            from: start
        )
        
        lastData =
        data
        
        drawWave(
            data
        )
        
        showWaveMsg(
            data
        )
    }
    
    func togglePoints() {
        guard let data =
                lastData else {
            return
        }
        
        state.pointsOn.toggle()
        
        drawWave(
            data
        )
        
        setMsg(
            state.pointsOn
            ? "GREEN = echo returned • RED = no clear echo"
            : "Showing the strongest result only"
        )
    }
    
    func toggleView() {
        clearWave()
        
        state.viewMode =
        state.viewMode == .first
        ? .third
        : .first
        
        object?.isEnabled =
        state.viewMode == .third
        
        if state.viewMode == .first {
            setMsg(
                "FIRST POV: waves start from the camera"
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
    
    private func makeStart(
        in view: ARView
    ) -> WaveStart? {
        if state.viewMode == .first {
            let matrix =
            view.cameraTransform.matrix
            
            let forward =
            simd_normalize(
                SIMD3<Float>(
                    -matrix.columns.2.x,
                     -matrix.columns.2.y,
                     -matrix.columns.2.z
                )
            )
            
            let right =
            simd_normalize(
                SIMD3<Float>(
                    matrix.columns.0.x,
                    matrix.columns.0.y,
                    matrix.columns.0.z
                )
            )
            
            let up =
            simd_normalize(
                SIMD3<Float>(
                    matrix.columns.1.x,
                    matrix.columns.1.y,
                    matrix.columns.1.z
                )
            )
            
            let cam =
            SIMD3<Float>(
                matrix.columns.3.x,
                matrix.columns.3.y,
                matrix.columns.3.z
            )
            
            let pos =
            cam
            + (forward * 0.18)
            - (up * 0.04)
            
            return WaveStart(
                pos: pos,
                forward: forward,
                right: right,
                up: up
            )
        }
        
        guard let waveStart else {
            return nil
        }
        
        let pos =
        waveStart.convert(
            position: .zero,
            to: nil
        )
        
        let forward =
        worldDir(
            SIMD3<Float>(
                0,
                0,
                -1
            ),
            from: waveStart
        )
        
        let right =
        worldDir(
            SIMD3<Float>(
                1,
                0,
                0
            ),
            from: waveStart
        )
        
        let up =
        worldDir(
            SIMD3<Float>(
                0,
                1,
                0
            ),
            from: waveStart
        )
        
        return WaveStart(
            pos: pos,
            forward: forward,
            right: right,
            up: up
        )
    }
    
    private func worldDir(
        _ dir: SIMD3<Float>,
        from source: Entity
    ) -> SIMD3<Float> {
        simd_normalize(
            source.convert(
                direction: dir,
                to: nil
            )
        )
    }
    
    private func drawWave(
        _ data: WaveData
    ) {
        removeWave()
        
        let view =
        waveDraw.make(
            from: data,
            showAllPoints:
                state.pointsOn
        )
        
        world.addChild(
            view
        )
        
        wave =
        view
        
        state.hasWave =
        true
    }
    
    private func showWaveMsg(
        _ data: WaveData
    ) {
        let setting =
        data.setting
        
        let pov =
        state.viewMode.title
        
        if let echo =
            data.nearestEcho,
           let time =
            data.echoMs {
            
            let distance =
            String(
                format: "%.2f m",
                Double(
                    echo.distanceM
                )
            )
            
            let delay =
            String(
                format: "%.1f ms",
                Double(time)
            )
            
            let frequency =
            "\(Int(setting.startKHz))"
            + "→"
            + "\(Int(setting.endKHz)) kHz"
            
            let direction =
            directionText(
                data
                    .strongestEcho?
                    .sideDeg
            )
            
            setMsg(
                "\(pov)"
                + " • ECHO RETURNED"
                + " • \(frequency)"
                + " • \(distance)"
                + " • \(delay)"
                + " • \(direction)"
            )
            
            return
        }
        
        if data.hitCount > 0 {
            setMsg(
                "\(pov)"
                + " • NO CLEAR ECHO"
                + " • sound reflected away or became too weak"
            )
            
            return
        }
        
        setMsg(
            "\(pov)"
            + " • no surface inside the wave area"
        )
    }
    
    private func directionText(
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
}
