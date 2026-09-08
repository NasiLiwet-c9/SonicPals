//
//  FPScanFloor.swift
//  POC
//
//  Created by Shan Newcastle on 18/08/26.
//

import RealityKit
import UIKit
import simd

@MainActor
final class FPScanFloor {
    private let sectors: Int
    private let radius: Float
    private let width: Float

    private let doneColor = UIColor(red: 0.25, green: 0.90, blue: 0.42, alpha: 1)

    private let scanColor = UIColor(red: 1.00, green: 0.74, blue: 0.24, alpha: 1)

    private var root = Entity()
    private var coverage = Entity()
    private var cursor = Entity()
    private var done: [Entity] = []
    private var head: Entity?

    private var planeP: SIMD3<Float>?
    private var planeN: SIMD3<Float>?

    private(set) var isPlaced = false

    init(
        sectors: Int = 24,
        radius: Float = 0.90,
        width: Float = 0.045
    ) {
        self.sectors = max(sectors, 8)
        self.radius = radius
        self.width = width
    }

    func reset(
        on parent: Entity
    ) {
        root.removeFromParent()

        root = Entity()
        root.name = "scanFloor"

        coverage = Entity()
        coverage.name = "scanCoverage"
        coverage.isEnabled = false

        cursor = makeCursor()
        cursor.name = "scanCursor"
        cursor.isEnabled = false

        root.addChild(coverage)
        root.addChild(cursor)
        parent.addChild(root)

        done.removeAll()
        head = nil
        planeP = nil
        planeN = nil
        isPlaced = false
    }

    func place(
        center: SIMD3<Float>,
        normal: SIMD3<Float>,
        baseYaw: Float
    ) {
        guard !isPlaced else {
            return }

        let normal = safeNormal(normal)

        planeP = center
        planeN = normal

        coverage.setPosition(center + (normal * 0.012), relativeTo: nil)

        coverage.setOrientation(alignY(normal), relativeTo: nil)

        let step = Float.pi * 2 / Float(sectors)
        let gap = min(2.0 * Float.pi / 180, step * 0.16)

        let ghost = ModelEntity(
            mesh: ringMesh(
                radius: radius,
                width: width * 0.60,
                start: 0,
                end: Float.pi * 2,
                segments: 144
            ),
            materials: [
                makeMat(color: .white, alpha: 0.035)
            ]
        )

        coverage.addChild(ghost)

        for index in 0..<sectors {
            let part = ModelEntity(
                mesh: ringMesh(
                    radius: radius,
                    width: width,
                    start: -(step * 0.5) + gap,
                    end: (step * 0.5) - gap,
                    segments: 8
                ),
                materials: [
                    makeMat(color: doneColor, alpha: 0.42)
                ]
            )

            let yaw = baseYaw + Float(index) * step

            part.orientation = simd_quatf(angle: -yaw, axis: SIMD3<Float>(0, 1, 0))

            part.isEnabled = false
            coverage.addChild(part)
            done.append(part)
        }

        let head = ModelEntity(
            mesh: ringMesh(
                radius: radius,
                width: width * 1.15,
                start: -(step * 0.34),
                end: step * 0.34,
                segments: 8
            ),
            materials: [
                makeMat(color: scanColor, alpha: 0.72)
            ]
        )

        coverage.addChild(head)
        self.head = head

        coverage.isEnabled = true
        isPlaced = true
    }

    func updateCoverage(
        seen: Set<Int>,
        yaw: Float
    ) {
        guard isPlaced else {
            return }

        for index in done.indices {
            done[index].isEnabled = seen.contains(index)
        }

        head?.orientation = simd_quatf(angle: -yaw, axis: SIMD3<Float>(0, 1, 0))
    }

    @discardableResult
    func updateCursor(
        origin: SIMD3<Float>,
        dir: SIMD3<Float>
    ) -> Bool {
        guard let planeP,
              let planeN else {
            cursor.isEnabled = false
            return false
        }

        let dir = simd_normalize(dir)
        let denom = simd_dot(dir, planeN)

        guard abs(denom) > 0.015 else {
            cursor.isEnabled = false
            return false
        }

        let t = simd_dot(
            planeP - origin,
            planeN
        ) / denom

        guard t >= 0.20,
              t <= 4.00 else {
            cursor.isEnabled = false
            return false
        }

        let pos = origin + (dir * t)

        cursor.setPosition(pos + (planeN * 0.014), relativeTo: nil)

        cursor.setOrientation(alignY(planeN), relativeTo: nil)

        cursor.isEnabled = true
        return true
    }

    func hideCursor() {
        cursor.isEnabled = false
    }

    func showHead() {
        guard isPlaced else {
            return }

        head?.isEnabled = true
    }

    func hideHead() {
        head?.isEnabled = false
    }

    private func makeCursor() -> Entity {
        let root = Entity()

        let outer = ModelEntity(
            mesh: ringMesh(
                radius: 0.16,
                width: 0.011,
                start: 0,
                end: Float.pi * 2,
                segments: 64
            ),
            materials: [
                makeMat(color: scanColor, alpha: 0.76)
            ]
        )

        let inner = ModelEntity(
            mesh: ringMesh(
                radius: 0.068,
                width: 0.005,
                start: 0,
                end: Float.pi * 2,
                segments: 48
            ),
            materials: [
                makeMat(color: scanColor, alpha: 0.36)
            ]
        )

        root.addChild(outer)
        root.addChild(inner)

        return root
    }

    private func ringMesh(
        radius: Float,
        width: Float,
        start: Float,
        end: Float,
        segments: Int
    ) -> MeshResource {
        let inner = max(radius - width, 0.001)

        let count = max(segments, 3)

        var pos: [SIMD3<Float>] = []
        var idx: [UInt32] = []

        pos.reserveCapacity((count + 1) * 2)

        idx.reserveCapacity(count * 6)

        for index in 0...count {
            let t = Float(index) / Float(count)

            let angle = start + ((end - start) * t)

            let s = sin(angle)
            let c = cos(angle)

            pos.append(SIMD3<Float>(s * radius, 0, -c * radius))

            pos.append(SIMD3<Float>(s * inner, 0, -c * inner))
        }

        for index in 0..<count {
            let a = UInt32(index * 2)
            let b = a + 1
            let c = UInt32((index + 1) * 2)
            let d = c + 1

            idx.append(contentsOf: [
                a,
                c,
                b,
                b,
                c,
                d
            ])
        }

        var desc = MeshDescriptor(name: "scanFloorRing")

        desc.positions = .init(pos)
        desc.primitives = .triangles(idx)

        return (try? MeshResource.generate(from: [desc]))
            ?? MeshResource.generatePlane(width: 0, depth: 0)
    }

    private func makeMat(
        color: UIColor,
        alpha: Float
    ) -> UnlitMaterial {
        var mat = UnlitMaterial(color: color)

        mat.faceCulling = .none
        mat.readsDepth = true
        mat.writesDepth = false

        mat.blending = .transparent(
            opacity: .init(floatLiteral: min(max(alpha, 0), 1))
        )

        return mat
    }

    private func safeNormal(
        _ value: SIMD3<Float>
    ) -> SIMD3<Float> {
        var value = value
        let length = simd_length(value)

        if length > 0.0001 {
            value /= length
        } else {
            value = SIMD3<Float>(0, 1, 0)
        }

        if value.y < 0 {
            value *= -1
        }

        return value
    }

    private func alignY(
        _ value: SIMD3<Float>
    ) -> simd_quatf {
        let from = SIMD3<Float>(0, 1, 0)

        let to = safeNormal(value)

        let dot = min(
            max(
                simd_dot(
                    from,
                    to
                ),
                -1
            ),
            1
        )

        if dot > 0.9999 {
            return simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
        }

        if dot < -0.9999 {
            return simd_quatf(angle: .pi, axis: SIMD3<Float>(1, 0, 0))
        }

        let axis = simd_normalize(simd_cross(from, to))

        return simd_quatf(angle: acos(dot), axis: axis)
    }
}
