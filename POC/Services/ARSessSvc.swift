//
//  ARSessSvc.swift
//  POC
//
//  Created by Shanon Newcastle on 30/07/26.
//  Updated by Shanon Newcastle on 03/08/26.
//

import ARKit
import RealityKit
import UIKit

@MainActor
final class ARSessSvc:
    ARSessionServing {
    
    func start(
        _ view: ARView
    ) -> Bool {
        let config =
        ARWorldTrackingConfiguration()
        
        config.planeDetection = [
            .horizontal,
            .vertical
        ]
        
        let supported =
        ARWorldTrackingConfiguration
            .supportsSceneReconstruction(
                .mesh
            )
        
        if supported {
            config.sceneReconstruction =
                .mesh
            
            view.environment
                .sceneUnderstanding
                .options = [
                    .collision,
                    .occlusion
                ]
            
            showMesh(
                true,
                in: view
            )
        }
        
        view.session.run(
            config,
            options: [
                .resetTracking,
                .removeExistingAnchors
            ]
        )
        
        return supported
    }
    
    func showMesh(
        _ show: Bool,
        in view: ARView
    ) {
        if show {
            view.debugOptions.insert(
                .showSceneUnderstanding
            )
        } else {
            view.debugOptions.remove(
                .showSceneUnderstanding
            )
        }
    }
    
    func addCoach(
        to view: ARView
    ) {
        let coach =
        ARCoachingOverlayView()
        
        coach.session =
        view.session
        
        coach.goal =
            .horizontalPlane
        
        coach.activatesAutomatically =
        true
        
        coach.translatesAutoresizingMaskIntoConstraints =
        false
        
        view.addSubview(
            coach
        )
        
        NSLayoutConstraint.activate([
            coach.topAnchor.constraint(
                equalTo:
                    view.topAnchor
            ),
            coach.bottomAnchor.constraint(
                equalTo:
                    view.bottomAnchor
            ),
            coach.leadingAnchor.constraint(
                equalTo:
                    view.leadingAnchor
            ),
            coach.trailingAnchor.constraint(
                equalTo:
                    view.trailingAnchor
            )
        ])
    }
}
