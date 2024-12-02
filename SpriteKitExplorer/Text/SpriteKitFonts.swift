//
//  SpriteKitFonts.swift
//  SpriteKitExplorer
//
//  Created by Achraf Kassioui on 02/12/2024.
//

import SpriteKit

// MARK: SpriteKit Fonts
/// Print on the console the fonts supported by SpriteKit
/// I sued this to choose fonts for label nodes
/// This log includes the fonts that were manually added to the Xcode project
func logAvailableFonts() {
    let fontFamilies = UIFont.familyNames
    for family in fontFamilies {
        print("Font Family: \(family)")
        let fontNames = UIFont.fontNames(forFamilyName: family)
        for fontName in fontNames {
            print("    Font: \(fontName)")
        }
    }
}
