//
//  ARMeshGeo+Read.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//

import ARKit
import simd

extension ARMeshGeometry {
    func vertex(
        at index: UInt32
    ) -> SIMD3<Float> {
        let pointer = vertices.buffer
            .contents()
            .advanced(
                by:
                    vertices.offset
                + (
                    vertices.stride
                    * Int(index)
                )
            )
        
        let value = pointer
            .assumingMemoryBound(
                to: (
                    Float,
                    Float,
                    Float
                ).self
            )
            .pointee
        
        return SIMD3<Float>(
            value.0,
            value.1,
            value.2
        )
    }
    
    func face(
        at index: Int
    ) -> [UInt32] {
        let count =
        faces.indexCountPerPrimitive
        
        let start =
        index
        * count
        * faces.bytesPerIndex
        
        return (0..<count).map {
            offset in
            
            let pointer = faces.buffer
                .contents()
                .advanced(
                    by:
                        start
                    + (
                        offset
                        * faces.bytesPerIndex
                    )
                )
            
            if faces.bytesPerIndex
                == MemoryLayout<UInt16>.size {
                return UInt32(
                    pointer
                        .assumingMemoryBound(
                            to: UInt16.self
                        )
                        .pointee
                )
            }
            
            return pointer
                .assumingMemoryBound(
                    to: UInt32.self
                )
                .pointee
        }
    }
}
