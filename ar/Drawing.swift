//
//  Drawing.swift
//  ar
//
//  Created by Nikolai Prokofev on 2024-08-06.
//

import Foundation
import ARKit
import CoreLocation

struct Drawing: Codable, Hashable, Identifiable {
    let title: String
    let coordinates: CLLocationCoordinate2D
    let points: [SCNVector3]
    
    var id: String {
        title + "\(coordinates.latitude)" + "\(coordinates.longitude)"
    }
    
    static func == (lhs: Drawing, rhs: Drawing) -> Bool {
        lhs.title == rhs.title && lhs.coordinates == rhs.coordinates
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(coordinates.latitude)
        hasher.combine(coordinates.longitude)
    }
}
