//
//  TextNode.swift
//  ar
//
//  Created by Nikolai Prokofev on 2024-08-06.
//

import Foundation
import ARKit
import CoreLocation

struct TextNode: Codable, Hashable, Identifiable {
    let text: String
    let coordinates: CLLocationCoordinate2D
    let position: SCNVector3
    
    var id: String {
        text + "\(coordinates.latitude)" + "\(coordinates.longitude)"
    }
    
    static func == (lhs: TextNode, rhs: TextNode) -> Bool {
        lhs.text == rhs.text && lhs.coordinates == rhs.coordinates
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(coordinates.latitude)
        hasher.combine(coordinates.longitude)
    }
}
