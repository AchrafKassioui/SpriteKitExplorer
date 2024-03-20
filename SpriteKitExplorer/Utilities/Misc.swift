//
//  Misc.swift
//  SpriteKitExplorer
//
//  Created by Achraf Kassioui on 19/3/2024.
//

import Foundation

func pointToString(_ point: CGPoint) -> String {
    let x = Int(round(point.x))
    let y = Int(round(point.y))
    return "\(x), \(y)"
}
