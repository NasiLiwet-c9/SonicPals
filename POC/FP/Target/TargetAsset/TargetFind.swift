//
//  TargetFind.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import RealityKit

enum TargetFind {
    static func one(
        named name: String,
        in root: Entity
    ) -> Entity? {
        if root.name == name {
            return root
        }

        for child in root.children {
            if let hit = one(
                named: name,
                in: child
            ) {
                return hit
            }
        }

        return nil
    }

    static func models(
        in root: Entity
    ) -> [Entity] {
        var out: [Entity] = []

        walk(
            root,
            into: &out
        )

        return out
    }

    static func inside(
        _ entity: Entity,
        named name: String
    ) -> Bool {
        var node: Entity? = entity

        while let cur = node {
            if cur.name == name {
                return true
            }

            node = cur.parent
        }

        return false
    }

    private static func walk(
        _ entity: Entity,
        into out: inout [Entity]
    ) {
        if entity.components.has(
            ModelComponent.self
        ) {
            out.append(entity)
        }

        for child in entity.children {
            walk(
                child,
                into: &out
            )
        }
    }
}
