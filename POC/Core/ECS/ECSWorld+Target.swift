//
//  ECSWorld+Target.swift
//  POC
//
//  Created by Shan Newcastle on 10/08/26.
//

import Foundation
import RealityKit
import simd

extension ECSWorld {
    func spawnTarget() {
        guard model.lidarOK,
              let scene = anchor.scene,
              var sessComp = sessEntity.components[SessComp.self],
              !sessComp.spawning
        else {
            return
        }

        sessComp.spawning = true
        sessEntity.components[SessComp.self] = sessComp

        setMsg("")

        Task { [weak self] in
            guard let self else {
                return
            }

            let ready = await targetMaker.prepare()

            guard var comp = sessEntity.components[SessComp.self] else {
                return
            }

            defer {
                comp.spawning = false
                sessEntity.components[SessComp.self] = comp
            }

            guard ready,
                  let part = targetMaker.make()
            else {
                setMsg(targetMaker.loadError ?? "Target could not load")
                return
            }

            guard let pose = targetSpawn.pose(
                session: sess.session,
                scene: scene,
                height: part.height
            ) else {
                setMsg("Scan more floor first")
                return
            }

            installTarget(
                part,
                pose: pose
            )
        }
    }

    func scanTarget(
        with data: WaveData,
        in scene: Scene
    ) {
        guard let targetEntity,
              var comp = targetEntity.components[TargetComp.self]
        else {
            return
        }

        let hits = targetWave.hitParts(
            target: targetEntity,
            comp: comp,
            data: data,
            in: scene
        )

        guard !hits.isEmpty else {
            return
        }
        
        let now =
            Date().timeIntervalSinceReferenceDate

        // ─────────────────────────────
        // FIND THE TREE
        // ─────────────────────────────
        //
        // Once the tree is found, `real.isEnabled` flips on (see
        // TargetSys) and the mango becomes eatable via proximity +
        // aim alone (see MangoEatSys) — no separate mango-scanning
        // step is required.

        guard !comp.found else {
            targetEntity.components[
                TargetComp.self
            ] = comp
            return
        }

        let treeHits = hits.filter {
            !comp.parts[$0].isMango
        }

        if !treeHits.isEmpty {
            setMsg("Tree hit!")
        }

        for index in treeHits
        where comp.parts.indices.contains(index) {

            comp.seenParts.insert(index)

            comp.pulseUntil[index] =
                now + 1.25

            comp.parts[index]
                .pulse
                .isEnabled = true

            comp.parts[index]
                .trace
                .isEnabled = true
        }

        targetEntity.components[
            TargetComp.self
        ] = comp
    }
    
    /// Called when the "eat" button is pressed while `eatCandidate`
    /// (the real, visible mango entity) is within reach and in view,
    /// per `MangoEatSys`.
    func eatMango() {
        guard let mango = eatCandidate else {
            return
        }

        mango.removeFromParent()

        model.mangoEatenCount += 1
        model.mangoEatReady = false

        eatCandidate = nil

        setMsg("Mango eaten!")
    }
    
    private func installTarget(
        _ part: TargetPart,
        pose: TargetPose
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
            parts: part.parts
        )

        anchor.addChild(part.root)

        targetEntity = part.root

        model.hasTarget = true
        model.targetFound = false
        model.msg = ""
    }
}
