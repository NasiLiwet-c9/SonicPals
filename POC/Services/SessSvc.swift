//
//  SessSvc.swift
//  POC
//
//  Created by Shanon Giuly Istanto on 10/08/26.
//

import ARKit
import RealityKit
import UIKit

@MainActor
protocol SessServing {
    func start(_ view: ARView) -> Bool
    func addCoach(to view: ARView)
}

@MainActor
final class SessSvc: SessServing {
    func start(_ view: ARView) -> Bool {
        let config = ARWorldTrackingConfiguration()

        config.planeDetection = [
            .horizontal,
            .vertical
        ]

        config.environmentTexturing = .none
        config.videoHDRAllowed = false

        if let format = balancedFormat() {
            config.videoFormat = format
        }

        let classified =
            ARWorldTrackingConfiguration
                .supportsSceneReconstruction(
                    .meshWithClassification
                )

        let plain =
            ARWorldTrackingConfiguration
                .supportsSceneReconstruction(
                    .mesh
                )

        if classified {
            config.sceneReconstruction = .meshWithClassification
        } else if plain {
            config.sceneReconstruction = .mesh
        }

        let supported = classified || plain

        if supported {
            view.environment.sceneUnderstanding.options = [
                .collision,
                .occlusion
            ]
        }

        view.debugOptions.remove(
            .showSceneUnderstanding
        )

        reduceCost(in: view)

        view.session.run(
            config,
            options: [
                .resetTracking,
                .removeExistingAnchors
            ]
        )

        return supported
    }

    func addCoach(to view: ARView) {
        let coach = ARCoachingOverlayView()

        coach.session = view.session
        coach.goal = .horizontalPlane
        coach.activatesAutomatically = true
        coach.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(coach)

        NSLayoutConstraint.activate([
            coach.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            coach.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),
            coach.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            coach.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            )
        ])
    }

    private func balancedFormat() -> ARConfiguration.VideoFormat? {
        let formats =
            ARWorldTrackingConfiguration
                .supportedVideoFormats
                .filter {
                    $0.framesPerSecond == 30
                }
                .sorted {
                    let a =
                        $0.imageResolution.width
                        * $0.imageResolution.height

                    let b =
                        $1.imageResolution.width
                        * $1.imageResolution.height

                    return a < b
                }

        return formats.first {
            $0.imageResolution.width >= 1_280
        }
        ?? formats.first
    }

    private func reduceCost(in view: ARView) {
        view.renderOptions.insert(.disableCameraGrain)
        view.renderOptions.insert(.disableMotionBlur)
        view.renderOptions.insert(.disableHDR)
    }
}
