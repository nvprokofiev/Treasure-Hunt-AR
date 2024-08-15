//
//  Tip.swift
//  ar
//
//  Created by Nikolai Prokofev on 2024-08-14.
//

import Foundation
import TipKit

struct InlineTip: Tip {
    var title: Text {
        Text("Switch to the Artist Mode")
    }

    var message: Text? {
        Text("Tap the area above three times to show the controls. Do the same to hide them.")
    }

    var image: Image? {
        Image(systemName: "paintpalette")
            .symbolRenderingMode(.multicolor)
    }
}
