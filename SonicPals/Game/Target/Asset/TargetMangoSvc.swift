//
//  TargetMangoSvc.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import RealityKit

@MainActor
struct TargetMangoSvc {
    private let names = [
        "MangoSpawnPoint1",
        "MangoSpawnPoint2",
        "MangoSpawnPoint3",
        "MangoSpawnPoint4",
        "MangoSpawnPoint5"
    ]

    func place(
        in root: Entity
    ) -> Bool {
        guard let mango = TargetFind.one(
            named: "MangoItem",
            in: root
        ),
        let parent = mango.parent else {
            debug(
                "MangoItem missing"
            )

            return false
        }

        let pts = names.compactMap {
            TargetFind.one(
                named: $0,
                in: root
            )
        }

        guard let pt = pts.randomElement() else {
            debug(
                "No mango spawn points"
            )

            return false
        }

        mango.position = pt.position(
            relativeTo: parent
        )

        debug(
            "mango -> \(pt.name)"
        )

        return true
    }

    func mark(
        in root: Entity
    ) -> Bool {
        guard let mango = TargetFind.one(
            named: "MangoItem",
            in: root
        ) else {
            return false
        }

        mango.name = "MangoTarget"

        return true
    }

    private func debug(
        _ text: String
    ) {
#if DEBUG
        print(
            "[TARGET ASSET] \(text)"
        )
#endif
    }
}
