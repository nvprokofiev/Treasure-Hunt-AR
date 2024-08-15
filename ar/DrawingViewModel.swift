//
//  DrawingViewModel.swift
//  ar
//
//  Created by Nikolai Prokofev on 2024-08-05.
//

import Foundation
import SwiftUI
import ARKit
import SCNLine

class DrawingViewModel: NSObject, ObservableObject {
    @Published var isDrawing = false
    @Published var location: CLLocation?
    @Published var isArtistMode = false
    @Published var showSuccess = false
    @Published var allDrawings: [Drawing] = []
    @Published var showSaveAlert = false
    @Published var found: UUID?
    @Published var radius: Double = 5

    var lastPoint: SCNVector3?
    var drawingNode: SCNLineNode?
    var sceneView: ARSCNView?
    let locationManger = LocationManager()
    private var addedNodes: [SCNLineNode] = []
        
    private let fileName = "data.json"
    
    override init() {
        super.init()
        self.allDrawings = loadDrawings(from: fileName) ?? []
        observeLocation()
    }

    func observeLocation() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            for await location in locationManger.locationStream.unsafelyUnwrapped {
                self.location = location
                
                guard !isArtistMode else { continue }
                var foundDrawing = false
                
                for drawing in allDrawings {

                    if location.coordinate.distance(from: drawing.coordinates) <= radius {
                        let node = initNode(with: drawing.points)
                        foundDrawing = true
                        found = UUID()

                        if addedNodes.isEmpty {
                            addedNodes.append(node)
                            placeNodeInFrontOfCamera(node: node, distance: 2)
                        }
                        break
                    }
                }

                if foundDrawing {
                    continue
                } else {
                    // remove all nodes when out of the region
                    addedNodes.forEach {
                        $0.removeFromParentNode()
                    }
                    addedNodes.removeAll()
                }
            }
        }
    }
    
    func placeNodeInFrontOfCamera(node: SCNNode, distance: Float) {
        guard let cameraNode = sceneView?.pointOfView else { return }
        let cameraOrientation = cameraNode.orientation
        
        let rotationMatrix = SCNMatrix4MakeRotation(cameraOrientation.w, cameraOrientation.x, cameraOrientation.y, cameraOrientation.z)
        
        let directionalVector = SCNVector3Make(0, 0.5, -distance)
        let positionVector = SCNVector3Make(
            directionalVector.x * rotationMatrix.m11 + directionalVector.y * rotationMatrix.m21 + directionalVector.z * rotationMatrix.m31,
            directionalVector.x * rotationMatrix.m12 + directionalVector.y * rotationMatrix.m22 + directionalVector.z * rotationMatrix.m32,
            directionalVector.x * rotationMatrix.m13 + directionalVector.y * rotationMatrix.m23 + directionalVector.z * rotationMatrix.m33
        )
        
        node.position = SCNVector3Make(
            cameraNode.position.x + positionVector.x,
            cameraNode.position.y + positionVector.y,
            cameraNode.position.z + positionVector.z
        )
        
        sceneView?.scene.rootNode.addChildNode(node)
    }

    func wipeAll() {
        saveDrawing([], to: fileName)
        addedNodes.forEach { $0.removeFromParentNode() }
        addedNodes.removeAll()
        allDrawings.removeAll()
        
    }
    
    func start() {
        guard !isDrawing else { return }
        drawingNode = initNode()
        isDrawing = true
    }
    
    func stop() {
        isDrawing = false
    }
    
    func reset() {
        drawingNode?.removeFromParentNode()
        drawingNode = nil
    }
    
    func delete(_ drawing: Drawing) {
        guard let index = allDrawings.firstIndex(where: { $0 == drawing }) else { return }
        allDrawings.remove(at: index)
        saveDrawing(allDrawings, to: fileName)
    }
    
    func capture() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        let bounds = UIScreen.main.bounds
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        window.drawHierarchy(in: bounds, afterScreenUpdates: true)
        guard let screenshot = UIGraphicsGetImageFromCurrentImageContext() else {
            return
        }
        UIGraphicsEndImageContext()
        UIImageWriteToSavedPhotosAlbum(screenshot, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving screenshot: \(error.localizedDescription)")
        } else {
            showSuccess = true
        }
    }
    
    func didTapSave() {
        Task { @MainActor in
            showSaveAlert = true
        }
    }
    
    func save(with name: String) {
        guard let drawingNode, let location else { return }
        var allDrawings = loadDrawings(from: fileName) ?? []
        let currentDrawing = Drawing(title: name, coordinates: location.coordinate, points: drawingNode.points)
        allDrawings.append(currentDrawing)
        self.drawingNode?.removeFromParentNode()
        self.drawingNode = nil
        
        saveDrawing(allDrawings, to: fileName)
        self.allDrawings = loadDrawings(from: fileName) ?? []
    }
    
    func saveDrawing(_ vectors: [Drawing], to fileName: String) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(vectors)
            
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent(fileName)
                try data.write(to: fileURL)
                print("Vectors saved successfully to: \(fileURL.path)")
            }
        } catch {
            print("Error saving vectors: \(error.localizedDescription)")
        }
    }
    
    func loadDrawings(from fileName: String) -> [Drawing]? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access document directory")
            return nil
        }
        
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let drawings = try decoder.decode([Drawing].self, from: data)
            return drawings
        } catch {
            print("Error loading vectors: \(error.localizedDescription)")
            return nil
        }
    }
    
    func initNode(with points: [SCNVector3] = []) -> SCNLineNode {
        let node = SCNLineNode(with: points, radius: 0.05, edges: 12, maxTurning: 12)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(
            displayP3Red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1
        )
        material.isDoubleSided = true
        node.lineMaterials = [material]
        return node
    }

    func updateGeometry(with point: SCNVector3) {
        drawingNode?.add(point: point)
    }
}
