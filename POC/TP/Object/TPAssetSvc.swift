//
//  TPAssetSvc.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//

import Foundation
import RealityKit
import simd

@MainActor
final class TPAssetSvc {
    private let name: String
    private let targetSpanM: Float
    
    private var template: Entity?
    private var task: Task<Entity, Error>?
    
    private(set) var loadError: String?
    
    init(
        name: String = "Bat3",
        targetSpanM: Float = 0.34
    ) {
        self.name = name
        self.targetSpanM = targetSpanM
    }
    
    func prepare() async -> Bool {
        if template != nil {
            return true
        }
        
        if let task {
            return await finish(task)
        }
        
        guard Bundle.main.url(
            forResource: name,
            withExtension: "usdz"
        ) != nil else {
            loadError =
            "Bat3.usdz is not included in the POC target"
            
            return false
        }
        
        let assetName = name
        
        let newTask = Task { @MainActor in
            try await Entity(
                named: assetName,
                in: Bundle.main
            )
        }
        
        task = newTask
        
        return await finish(
            newTask
        )
    }
    
    func makeBody() -> TPBody? {
        guard let template else {
            loadError =
            "Bat3.usdz has not finished loading"
            
            return nil
        }
        
        let entity = template.clone(
            recursive: true
        )
        
        entity.name = "batBody"
        
        let bounds = entity.visualBounds(
            recursive: true,
            relativeTo: entity,
            excludeInactive: false
        )
        
        let sourceSize = bounds.extents
        
        let largest = max(
            sourceSize.x,
            max(
                sourceSize.y,
                sourceSize.z
            )
        )
        
        guard largest > 0.001 else {
            loadError =
            "Bat3.usdz loaded, but its visible bounds are empty"
            
            return nil
        }
        
        let scale =
        targetSpanM
        / largest
        
        let size =
        sourceSize
        * scale
        
        let center =
        bounds.center
        * scale
        
        entity.scale = SIMD3<Float>(
            repeating: scale
        )
        
        // Centers the complete visible USDZ hierarchy
        // on the object root.
        entity.position = -center
        
        loadError = nil
        
        return TPBody(
            entity: entity,
            size: size
        )
    }
    
    private func finish(
        _ task: Task<Entity, Error>
    ) async -> Bool {
        do {
            template = try await task.value
            
            self.task = nil
            loadError = nil
            
            return true
        } catch {
            self.task = nil
            
            loadError =
            "Bat3.usdz failed to load: "
            + error.localizedDescription
            
            return false
        }
    }
}
