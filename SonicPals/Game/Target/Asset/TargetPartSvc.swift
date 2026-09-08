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
        guard let space =
            pulse.parent else {
            return nil
        }

        let ps = TargetFind.models(in: pulse)

        let ts = TargetFind.models(in: trace)

        guard ps.count
                == ts.count else {
            return nil
        }

        var out: [TargetEchoPart] = []

        out.reserveCapacity(ps.count)

        for i in ps.indices {
            let p = ps[i]
            let t = ts[i]

            let b =
                p.visualBounds(
                    recursive: false,
                    relativeTo: space,
                    excludeInactive: false
                )

            guard b.extents.x > 0.001 || b.extents.y > 0.001
                    || b.extents.z > 0.001 else {
                continue
            }

            let half = b.extents * 0.5

            let r = max(simd_length(half), 0.02)

            let n = p.name
                .trimmingCharacters(in: .whitespacesAndNewlines)

            out.append(
                TargetEchoPart(
                    name: n.isEmpty
                        ? "part\(i)"
                        : n,
                    pulse: p,
                    trace: t,
                    center: b.center,
                    half: half,
                    radius: r,
                    isMango: TargetFind.inside(p, named: "MangoTarget")
                )
            )
        }

        return out
    }
}
