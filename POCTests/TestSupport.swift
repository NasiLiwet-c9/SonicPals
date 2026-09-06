//
//  TestSupport.swift
//  POCTests
//
//  Created by Shan Newcastle on 05/09/26.
//

import ARKit
import Foundation
import RealityKit
import SonarCore
import simd

@testable import POC

// MARK: - Notifications

/// `post` is synchronous, so anything sent during a `step` has landed
/// by the time it returns
@MainActor
final class NotificationSpy {
    private(set) var received: [Notification] = []

    private let center = NotificationCenter.default
    private var tokens: [NSObjectProtocol] = []

    init(_ names: Notification.Name...) {
        for name in names {
            let token = center.addObserver(
                forName: name,
                object: nil,
                queue: nil
            ) { [weak self] note in
                MainActor.assumeIsolated {
                    self?.received.append(note)
                }
            }

            tokens.append(token)
        }
    }

    deinit {
        let center = center
        let tokens = tokens

        for token in tokens {
            center.removeObserver(token)
        }
    }

    var names: [Notification.Name] {
        received.map(\.name)
    }

    func count(of name: Notification.Name) -> Int {
        received.filter { $0.name == name }.count
    }

    func cues() -> [TargetCue] {
        received.compactMap { $0.object as? TargetCue }
    }

    func clear() {
        received.removeAll()
    }
}

// MARK: - Cameras

enum TestCamera {
    /// Level, looking along -Z
    static func level(at position: SIMD3<Float> = .zero) -> simd_float4x4 {
        var m = matrix_identity_float4x4
        m.columns.3 = SIMD4<Float>(position.x, position.y, position.z, 1)
        return m
    }

    /// Positive `yaw` turns left, positive `pitch` looks up
    static func posed(
        yaw: Float = 0,
        pitch: Float = 0,
        at position: SIMD3<Float> = .zero
    ) -> simd_float4x4 {
        let rotation = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
            * simd_quatf(angle: pitch, axis: SIMD3<Float>(1, 0, 0))

        var m = simd_float4x4(rotation)
        m.columns.3 = SIMD4<Float>(position.x, position.y, position.z, 1)
        return m
    }
}

// MARK: - Target fixtures

enum TestTarget {
    /// Detached, which is all the systems need
    static func make(
        at position: SIMD3<Float> = SIMD3<Float>(0, 0, -2),
        partCount: Int = 2,
        mangoIndices: Set<Int> = [1]
    ) -> (entity: Entity, real: Entity, parts: [TargetEchoPart]) {
        let root = Entity()
        let real = Entity()
        real.isEnabled = false
        root.addChild(real)

        var parts: [TargetEchoPart] = []

        for index in 0..<partCount {
            let pulse = Entity()
            let trace = Entity()
            pulse.isEnabled = false
            trace.isEnabled = false
            root.addChild(pulse)
            root.addChild(trace)

            parts.append(
                TargetEchoPart(
                    name: "part\(index)",
                    pulse: pulse,
                    trace: trace,
                    center: SIMD3<Float>(0, Float(index) * 0.5, 0),
                    half: SIMD3<Float>(0.1, 0.1, 0.1),
                    radius: 0.15,
                    isMango: mangoIndices.contains(index)
                )
            )
        }

        root.components.set(
            TargetComp(
                real: real,
                parts: parts,
                lockPos: position,
                lockYaw: 0
            )
        )

        root.setPosition(position, relativeTo: nil)

        return (root, real, parts)
    }

    static func comp(_ entity: Entity) -> TargetComp {
        entity.components[TargetComp.self]!
    }

    static func setComp(_ entity: Entity, _ body: (inout TargetComp) -> Void) {
        var comp = entity.components[TargetComp.self]!
        body(&comp)
        entity.components[TargetComp.self] = comp
    }
}

// MARK: - Wave fixtures

enum TestWave {
    static func data(
        from position: SIMD3<Float> = .zero,
        maxDistance: Float = 1.5,
        setting: WaveSetting = WaveSet.standard.far,
        hits: [WaveHit] = []
    ) -> WaveData {
        WaveData(
            start: WaveStart(
                pos: position,
                forward: SIMD3<Float>(0, 0, -1),
                right: SIMD3<Float>(1, 0, 0),
                up: SIMD3<Float>(0, 1, 0)
            ),
            setting: setting,
            hits: hits,
            rayCount: hits.count,
            maxDistance: maxDistance,
            soundSpeed: 343
        )
    }
}

// MARK: - Reveal fixtures

enum TestReveal {
    static func layer(
        delayMs: Int64,
        zone: FPZone
    ) -> FPMeshLayer {
        FPMeshLayer(
            root: Entity(),
            pulse: Entity(),
            trace: Entity(),
            delayMs: delayMs,
            zone: zone
        )
    }
}

/// Stands in for ARKit room geometry
@MainActor
final class StubMeshBuilder: FPMeshBuilding {
    var layers: [FPMeshLayer]
    private(set) var callCount = 0

    init(layers: [FPMeshLayer] = []) {
        self.layers = layers
    }

    func make(session: ARSession, from data: WaveData) -> [FPMeshLayer] {
        callCount += 1
        return layers
    }
}
