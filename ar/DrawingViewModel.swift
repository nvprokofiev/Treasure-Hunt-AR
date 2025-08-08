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
    @Published var allTextNodes: [TextNode] = []
    @Published var showSaveAlert = false
    @Published var showTextAlert = false
    @Published var found: UUID?
    @Published var radius: Double = 5
    @Published var isFreeHand = false

    var lastPoint: SCNVector3?
    var drawingNode: SCNLineNode?
    var sceneView: ARSCNView?
    let locationManger = LocationManager()
    private var addedNodes: [SCNLineNode] = []
    private var addedTextNodes: [SCNNode] = []
        
    private let fileName = "data.json"
    private let textFileName = "textdata.json"
    
    override init() {
        super.init()
        self.allDrawings = loadDrawings(from: fileName) ?? []
        self.allTextNodes = loadTextNodes(from: textFileName) ?? []
        observeLocation()
    }

    func observeLocation() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            for await location in locationManger.locationStream.unsafelyUnwrapped {
                self.location = location
                
                if isArtistMode && found != nil {
                    wipeScreen()
                }
                
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
                
                // Check for text nodes
                for textNode in allTextNodes {
                    if location.coordinate.distance(from: textNode.coordinates) <= radius {
                        let node = createCoolTextNode(from: textNode) // Use the cooler version
                        foundDrawing = true
                        found = UUID()

                        if addedTextNodes.isEmpty {
                            addedTextNodes.append(node)
                            placeNodeInFrontOfCamera(node: node, distance: 2)
                        }
                        break
                    }
                }

                if foundDrawing {
                    continue
                } else {
                    wipeScreen()
                }
            }
        }
    }
    
    private func wipeScreen() {
        // remove all nodes when out of the region
        addedNodes.forEach {
            $0.removeFromParentNode()
        }
        addedNodes.removeAll()
        
        addedTextNodes.forEach {
            $0.removeFromParentNode()
        }
        addedTextNodes.removeAll()
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
        saveTextNodes([], to: textFileName)
        addedNodes.forEach { $0.removeFromParentNode() }
        addedNodes.removeAll()
        addedTextNodes.forEach { $0.removeFromParentNode() }
        addedTextNodes.removeAll()
        allDrawings.removeAll()
        allTextNodes.removeAll()
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
    
    func didTapFreeHand() {
        Task { @MainActor in
            isFreeHand.toggle()
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
    
    // MARK: - Text Node Methods
    
    func didTapText() {
        Task { @MainActor in
            showTextAlert = true
            isFreeHand = false
        }
    }
    
    func saveText(_ text: String) {
        guard let location else { return }
        
        // Get camera position for text placement
        guard let cameraNode = sceneView?.pointOfView else { return }
        let cameraPosition = cameraNode.position
        
        var allTextNodes = loadTextNodes(from: textFileName) ?? []
        let currentTextNode = TextNode(
            text: text,
            coordinates: location.coordinate,
            position: cameraPosition
        )
        allTextNodes.append(currentTextNode)
        
        saveTextNodes(allTextNodes, to: textFileName)
        self.allTextNodes = loadTextNodes(from: textFileName) ?? []
    }
    
    func deleteText(_ textNode: TextNode) {
        guard let index = allTextNodes.firstIndex(where: { $0 == textNode }) else { return }
        allTextNodes.remove(at: index)
        saveTextNodes(allTextNodes, to: textFileName)
    }
    
    // Alternative cool text style with gradient and particles
    func createCoolTextNode(from textNode: TextNode) -> SCNNode {
        // Main text geometry
        let textGeometry = SCNText(string: textNode.text, extrusionDepth: 0.2)
        textGeometry.font = UIFont.boldSystemFont(ofSize: 0.7)
        textGeometry.chamferRadius = 0.03
        
        // Create gradient material
        let material = SCNMaterial()
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 256, height: 256)

        // Generate a set of random colors for the gradient
        let randomColors: [CGColor] = [
            UIColor.random().cgColor,
            UIColor.random().cgColor,
            UIColor.random().cgColor
        ]
        gradientLayer.colors = randomColors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        material.diffuse.contents = gradientImage
        material.emission.contents = gradientImage // Use the gradient image for the glow too
        material.emission.intensity = 1.2 // Adjust intensity to your liking
        material.lightingModel = .physicallyBased
        material.metalness.contents = 0.9
        material.roughness.contents = 0.1

        textGeometry.materials = [material]
        
        // Create main text node
        let textNode3D = SCNNode(geometry: textGeometry)
        
        // Enable shadows for the text
        textNode3D.castsShadow = true
        
        // Center the text
        let (min, max) = textGeometry.boundingBox
        let dx = Float(max.x - min.x)
        let dy = Float(max.y - min.y)
        let dz = Float(max.z - min.z)
        textNode3D.pivot = SCNMatrix4MakeTranslation(dx/2, dy/2, dz/2)
        
        // Add lightning particle system
        let lightningSystem = SCNParticleSystem()
        lightningSystem.emitterShape = textGeometry
        lightningSystem.particleImage = UIImage(systemName: "bolt.fill")
        lightningSystem.birthRate = 150
        lightningSystem.particleSize = 0.03
        lightningSystem.particleColor = .cyan
        lightningSystem.particleLifeSpan = 0.5
        lightningSystem.particleLifeSpanVariation = 0.2
        lightningSystem.emissionDuration = 0
        lightningSystem.spreadingAngle = 180
        textNode3D.addParticleSystem(lightningSystem)
        
        // Create container
        let containerNode = SCNNode()
        containerNode.position = textNode.position
        containerNode.addChildNode(textNode3D)

        // Add subtle scale animation
        let scaleUp = SCNAction.scale(to: 1.05, duration: 2.0)
        let scaleDown = SCNAction.scale(to: 0.95, duration: 2.0)
        let scaleSequence = SCNAction.sequence([scaleUp, scaleDown])
        let scaleRepeat = SCNAction.repeatForever(scaleSequence)
        containerNode.runAction(scaleRepeat)

        // Start repeating confetti when text node is created
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startRepeatingConfetti(for: containerNode)
        }

        return containerNode
    }
    
    // MARK: - Confetti System
    
    func startRepeatingConfetti(for parentNode: SCNNode) {
        // Initial confetti burst
        createConfetti(parentNode: parentNode)
        
        // Set up repeating confetti every 3 seconds
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            // Check if the parent node still exists in the scene
            if parentNode.parent != nil {
                self.createConfetti(parentNode: parentNode)
            } else {
                // Stop the timer if the node is no longer in the scene
                timer.invalidate()
            }
        }
    }
    
    func createConfetti(parentNode: SCNNode) {
        let confettiCount = 150
        let colors: [UIColor] = [
            .systemRed, .systemBlue, .systemGreen, .systemYellow,
            .systemPurple, .systemOrange, .systemPink, .systemTeal
        ]
        
        for i in 0..<confettiCount {
            // Create confetti piece
            let confettiGeometry = SCNBox(width: 0.02, height: 0.02, length: 0.02, chamferRadius: 0.005)
            let confettiMaterial = SCNMaterial()
            confettiMaterial.diffuse.contents = colors[i % colors.count]
            confettiMaterial.metalness.contents = 0.3
            confettiMaterial.roughness.contents = 0.7
            confettiGeometry.materials = [confettiMaterial]
            
            let confettiNode = SCNNode(geometry: confettiGeometry)
            
            // Random position around the text (relative to the parent node)
            // Position confetti in front of the text node
            let randomX = Float.random(in: -0.8...0.8)
            let randomY = Float.random(in: 0.0...0.8)
            let randomZ = Float.random(in: 0.1...0.5) // Positive Z to place in front
            confettiNode.position = SCNVector3(randomX, randomY, randomZ)
            
            // Add to the parent node (the text node) instead of the root node
            parentNode.addChildNode(confettiNode)
            
            // Create explosion animation
            let explosionDistance = Float.random(in: 0.5...2.0)
            let explosionDirection = SCNVector3(
                Float.random(in: -1...1),
                Float.random(in: 0.5...2.0), // Always go up
                Float.random(in: 0.5...1.5) // Move forward and outward
            ).normalized()
            
            let explosionPosition = SCNVector3(
                confettiNode.position.x + explosionDirection.x * explosionDistance,
                confettiNode.position.y + explosionDirection.y * explosionDistance,
                confettiNode.position.z + explosionDirection.z * explosionDistance
            )
            
            // Move animation
            let moveAction = SCNAction.move(to: explosionPosition, duration: Double.random(in: 1.5...3.0))
            
            // Rotation animation
            let rotateX = SCNAction.rotateBy(x: CGFloat.random(in: 2...6), y: 0, z: 0, duration: 1.0)
            let rotateY = SCNAction.rotateBy(x: 0, y: CGFloat.random(in: 2...6), z: 0, duration: 1.0)
            let rotateZ = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat.random(in: 2...6), duration: 1.0)
            let rotateAction = SCNAction.group([rotateX, rotateY, rotateZ])
            let repeatRotate = SCNAction.repeatForever(rotateAction)
            
            // Scale animation
            let scaleAction = SCNAction.scale(to: 0.1, duration: 2.0)
            
            // Fade out animation
            let fadeAction = SCNAction.fadeOut(duration: 2.0)
            
            // Group all animations
            let groupAction = SCNAction.group([moveAction, repeatRotate, scaleAction, fadeAction])
            
            // Remove node after animation
            let removeAction = SCNAction.removeFromParentNode()
            let sequence = SCNAction.sequence([groupAction, removeAction])
            
            // Start animation with slight delay for staggered effect
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                confettiNode.runAction(sequence)
            }
        }
    }
    
    func saveTextNodes(_ textNodes: [TextNode], to fileName: String) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(textNodes)
            
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent(fileName)
                try data.write(to: fileURL)
                print("Text nodes saved successfully to: \(fileURL.path)")
            }
        } catch {
            print("Error saving text nodes: \(error.localizedDescription)")
        }
    }
    
    func loadTextNodes(from fileName: String) -> [TextNode]? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access document directory")
            return nil
        }
        
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let textNodes = try decoder.decode([TextNode].self, from: data)
            return textNodes
        } catch {
            print("Error loading text nodes: \(error.localizedDescription)")
            return nil
        }
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0
        )
    }
}
