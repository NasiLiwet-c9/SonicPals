//
//  FPMeshRead.swift
//  POC
//
//  Created by Shanon Newcastle on 04/08/26.
//

import ARKit
import RealityKit
import simd

@MainActor
final class FPMeshRead:
    FPMeshReadPort {
    
    private let anchorSamples = 24
    
    func read(
        in view: ARView,
        cone: FPConeScan,
        limit: Int
    ) -> [FPTri] {
        guard let frame =
                view.session.currentFrame else {
            return []
        }
        
        let anchors = frame.anchors.compactMap {
            $0 as? ARMeshAnchor
        }
        
        var result: [FPTri] = []
        var checked = 0
        
        anchorLoop: for anchor in anchors {
            guard anchorMatches(
                anchor,
                cone: cone
            ) else {
                continue
            }
            
            let geo = anchor.geometry
            
            for faceIndex in 0..<geo.faces.count {
                checked += 1
                
                guard checked <= limit else {
                    break anchorLoop
                }
                
                let face = geo.face(
                    at: faceIndex
                )
                
                guard face.count == 3 else {
                    continue
                }
                
                let tri = FPTri(
                    a: worldPos(
                        geo.vertex(
                            at: face[0]
                        ),
                        transform:
                            anchor.transform
                    ),
                    b: worldPos(
                        geo.vertex(
                            at: face[1]
                        ),
                        transform:
                            anchor.transform
                    ),
                    c: worldPos(
                        geo.vertex(
                            at: face[2]
                        ),
                        transform:
                            anchor.transform
                    )
                )
                
                let inside = tri.points.contains {
                    cone.contains(
                        $0,
                        pad: 1.22
                    )
                }
                
                guard inside else {
                    continue
                }
                
                result.append(tri)
            }
        }
        
        return result
    }
    
    private func anchorMatches(
        _ anchor: ARMeshAnchor,
        cone: FPConeScan
    ) -> Bool {
        let geo = anchor.geometry
        let count = geo.vertices.count
        
        guard count > 0 else {
            return false
        }
        
        let step = max(
            count / anchorSamples,
            1
        )
        
        for index in stride(
            from: 0,
            to: count,
            by: step
        ) {
            let point = worldPos(
                geo.vertex(
                    at: UInt32(index)
                ),
                transform:
                    anchor.transform
            )
            
            if cone.contains(
                point,
                pad: 1.3
            ) {
                return true
            }
        }
        
        return false
    }
    
    private func worldPos(
        _ local: SIMD3<Float>,
        transform: simd_float4x4
    ) -> SIMD3<Float> {
        let world =
        transform
        * SIMD4<Float>(
            local.x,
            local.y,
            local.z,
            1
        )
        
        return SIMD3<Float>(
            world.x,
            world.y,
            world.z
        )
    }
}
