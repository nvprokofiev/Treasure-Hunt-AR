//
//  ARViewContainer.swift
//  ar
//
//  Created by Nikolai Prokofev on 2024-08-14.
//

import Foundation
import ARKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: DrawingViewModel
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.delegate = context.coordinator
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        arView.session.run(config)
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.viewModel = viewModel
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARViewContainer
        var viewModel: DrawingViewModel
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
            self.viewModel = parent.viewModel
        }

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            guard let sceneView = renderer as? ARSCNView else { return }
            if viewModel.sceneView == nil {
                viewModel.sceneView = sceneView
            }
            
            if viewModel.isDrawing {
                guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else { return }
                
                var translation = matrix_identity_float4x4
                translation.columns.3.z = -1 // 0.5 meters in front of the camera
                
                let positionInFrontOfCamera = cameraTransform * translation
                let point = SCNVector3(
                    positionInFrontOfCamera.columns.3.x,
                    positionInFrontOfCamera.columns.3.y,
                    positionInFrontOfCamera.columns.3.z
                )
                
                if let drawingNode = viewModel.drawingNode {
                    viewModel.updateGeometry(with: point)
                    sceneView.scene.rootNode.addChildNode(drawingNode)
                }
                
                viewModel.lastPoint = point
            } else {
                viewModel.lastPoint = nil
            }
        }
    }
}
