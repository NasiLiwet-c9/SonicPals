//
//  ECSWorld+Target.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
//

import Foundation
import RealityKit
import simd

extension ECSWorld {
    func spawnTarget() {
        guard let ar, model.lidarOK else {
            return
        }

        var sessComp =
            sessEntity.components[SessComp.self]
            ?? SessComp()

        guard !sessComp.spawning else {
            return
        }

        sessComp.spawning = true
        sessEntity.components[SessComp.self] = sessComp

        setMsg("")

        Task { [weak self] in
            guard let self else {
                return
            }

            let ready = await self.targetMaker.prepare()

            var comp =
                self.sessEntity.components[SessComp.self]
                ?? SessComp()

            defer {
                comp.spawning = false
                self.sessEntity.components[SessComp.self] = comp
            }

            guard ready,
                  let part = self.targetMaker.make() else {
                self.setMsg(
                    self.targetMaker.loadError
                    ?? "Target could not load"
                )
                return
            }

            guard let pose = self.targetSpawn.pose(
                in: ar,
                height: part.height
            ) else {
                self.setMsg("Scan more floor first")
                return
            }

            self.installTarget(
                part,
                pose: pose,
                in: ar
            )
        }
    }

    func scanTarget(
        with data: WaveData,
        in view: ARView
    ) {
        guard let targetEntity,
              var comp =
                targetEntity.components[TargetComp.self],
              !comp.found else {
            return
        }

        let hits = targetWave.hitParts(
            target: targetEntity,
            comp: comp,
            data: data,
            in: view
        )

        guard !hits.isEmpty else {
            return
        }

        let now =
            Date().timeIntervalSinceReferenceDate

        for index in hits
        where comp.parts.indices.contains(index) {
            comp.seenParts.insert(index)
            comp.pulseUntil[index] = now + 1.25

            comp.parts[index].pulse.isEnabled = true
            comp.parts[index].trace.isEnabled = true
        }

        targetEntity.components[TargetComp.self] = comp
    }

    private func installTarget(
        _ part: TargetPart,
        pose: TargetPose,
        in view: ARView
    ) {
        clearActiveWave()
        clearTraces()

        targetEntity?.removeFromParent()

        part.root.setPosition(
            pose.pos,
            relativeTo: nil
        )

        part.root.setOrientation(
            simd_quatf(
                angle: pose.yaw,
                axis: SIMD3<Float>(0, 1, 0)
            ),
            relativeTo: nil
        )

        part.root.components[TargetComp.self] = TargetComp(
            real: part.real,
            parts: part.parts,
            view: ARViewRef(view)
        )

        anchor.addChild(part.root)

        targetEntity = part.root

        model.hasTarget = true
        model.targetFound = false
        model.msg = ""
    }
}
