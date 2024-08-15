//
//  SCNVector3+Extensions.swift
//  ar
//
//  Created by Nikolai Prokofev on 2024-08-14.
//

import Foundation
import ARKit

extension SCNVector3: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y, z
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(Float.self, forKey: .x)
        let y = try container.decode(Float.self, forKey: .y)
        let z = try container.decode(Float.self, forKey: .z)
        self.init(x, y, z)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(z, forKey: .z)
    }
}

