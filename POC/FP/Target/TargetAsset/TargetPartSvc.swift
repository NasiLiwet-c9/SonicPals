//
//  TargetPartSvc.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import Foundation
import RealityKit
import simd

@MainActor
struct TargetPartSvc {
    func make(
        pulse: Entity,
        trace: Entity
    ) -> [TargetEchoPart]? {
        let ps = TargetFind.models(
            in: pulse
        )

        let ts = TargetFind.models(
            in: trace
        )

        guard ps.count == ts.count else {
            return nil
        }

        var out: [TargetEchoPart] = []

        out.reserveCapacity(
            ps.count
        )

        for i in ps.indices {
            let p = ps[i]
            let t = ts[i]

            let b = p.visualBounds(
                recursive: false,
                relativeTo: pulse,
                excludeInactive: false
            )

            guard b.extents.x > 0.001
                || b.extents.y > 0.001
                || b.extents.z > 0.001 else {
                continue
            }

            let r = max(
                simd_length(
                    b.extents
                ) * 0.5,
                0.04
            )

            let n = p.name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            out.append(
                TargetEchoPart(
                    name:
                        n.isEmpty
                        ? "part\(i)"
                        : n,
                    pulse: p,
                    trace: t,
                    center: b.center,
                    half: b.extents * 0.5,
                    radius: r,
                    isMango: TargetFind.inside(
                        p,
                        named: "MangoTarget"
                    )
                )
            )
        }

        return out
    }
}
