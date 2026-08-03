//
//  SceneCtrl+FPAnim.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//

import RealityKit

extension SceneCtrl {
    func startFP(
        _ data: WaveData,
        in view: ARView,
        root: Entity
    ) {
        visTask?.cancel()
        
        visTask = Task {
            [weak self, weak view, weak root] in
            
            guard let self,
                  let view,
                  let root else {
                return
            }
            
            let layers = await self.loadFPMesh(
                data,
                in: view,
                root: root
            )
            
            guard !Task.isCancelled,
                  root.parent != nil else {
                return
            }
            
            if layers.isEmpty {
                try? await Task.sleep(
                    for: .milliseconds(1_500)
                )
                
                guard !Task.isCancelled else {
                    return
                }
                
                self.finishFP(root)
                return
            }
            
            let shown = await self.revealFP(
                layers,
                root: root
            )
            
            guard shown,
                  !Task.isCancelled else {
                return
            }
            
            try? await Task.sleep(
                for: .seconds(6)
            )
            
            guard !Task.isCancelled else {
                return
            }
            
            let hidden = await self.hideFP(
                layers,
                root: root
            )
            
            guard hidden,
                  !Task.isCancelled else {
                return
            }
            
            self.finishFP(root)
        }
    }
    
    private func loadFPMesh(
        _ data: WaveData,
        in view: ARView,
        root: Entity
    ) async -> [FPMeshLayer] {
        for attempt in 0..<4 {
            guard !Task.isCancelled,
                  root.parent != nil else {
                return []
            }
            
            let layers = fpMesh.make(
                in: view,
                from: data
            )
            
            if !layers.isEmpty {
                for layer in layers {
                    layer.root.isEnabled = false
                    
                    root.addChild(
                        layer.root
                    )
                }
                
                return layers
            }
            
            guard attempt < 3 else {
                break
            }
            
            try? await Task.sleep(
                for: .milliseconds(140)
            )
        }
        
        return []
    }
    
    private func revealFP(
        _ layers: [FPMeshLayer],
        root: Entity
    ) async -> Bool {
        let sorted = layers.sorted {
            $0.delayMs < $1.delayMs
        }
        
        var elapsedMs: Int64 = 0
        
        for layer in sorted {
            let waitMs = max(
                layer.delayMs - elapsedMs,
                0
            )
            
            try? await Task.sleep(
                for: .milliseconds(waitMs)
            )
            
            guard !Task.isCancelled,
                  root.parent != nil else {
                return false
            }
            
            layer.root.isEnabled = true
            elapsedMs = layer.delayMs
        }
        
        return true
    }
    
    private func hideFP(
        _ layers: [FPMeshLayer],
        root: Entity
    ) async -> Bool {
        for zone in [
            FPZone.core,
            FPZone.soft,
            FPZone.edge
        ] {
            guard !Task.isCancelled,
                  root.parent != nil else {
                return false
            }
            
            for layer in layers
            where layer.zone == zone {
                layer.root.isEnabled = false
            }
            
            try? await Task.sleep(
                for: .milliseconds(120)
            )
        }
        
        return true
    }
    
    private func finishFP(
        _ root: Entity
    ) {
        root.removeFromParent()
        
        guard fpRoot === root else {
            return
        }
        
        fpRoot = nil
        state.hasWave = false
        push()
    }
}
