//
//  ARMesh+Read.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import ARKit
import simd

extension ARMeshGeometry {
    func vertex(at index: UInt32) -> SIMD3<Float> {
        let ptr =
            vertices.buffer.contents().advanced(
                by: vertices.offset + (vertices.stride * Int(index))
            )

        let value = ptr.assumingMemoryBound(to: (Float, Float, Float).self)
            .pointee

        return SIMD3<Float>(value.0, value.1, value.2)
    }

    func face(at index: Int) -> [UInt32] {
        let count = faces.indexCountPerPrimitive

        let start = index * count * faces.bytesPerIndex

        return (0..<count).map { offset in
            let ptr = faces.buffer.contents().advanced(by: start + (offset * faces.bytesPerIndex))

            if faces.bytesPerIndex
                == MemoryLayout<UInt16>.size {
                return UInt32(ptr.assumingMemoryBound(to: UInt16.self) .pointee)
            }

            return ptr.assumingMemoryBound(to: UInt32.self)
            .pointee
        }
    }
}
