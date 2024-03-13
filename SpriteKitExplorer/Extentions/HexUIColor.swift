/**
 
 # A UIColor extension to support Hex colors
 
 Usage:
 
 ```
 guard let myColor = UIColor(hex: "e10000") else { print("Hex color does not exist"); return }
 
 ```
 
 The extension requires that you import a framework that understands UIColor, such as UIKit, SwiftUI, or SpriteKit
 
 Created: 12 March 2024
 Credit: https://www.hackingwithswift.com/example-code/uicolor/how-to-convert-a-hex-color-to-a-uicolor
 Edited to accept both opaque and transparent Hex colors
 
 */

import SpriteKit

extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        let start: String.Index
        if hex.hasPrefix("#") {
            start = hex.index(hex.startIndex, offsetBy: 1)
        } else {
            start = hex.startIndex
        }
        
        let hexColor = String(hex[start...])
        
        if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000FF) / 255
                a = 1.0 // Default to fully opaque
                self.init(red: r, green: g, blue: b, alpha: a)
                return
            }
        } else if hexColor.count == 8 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xFF000000) >> 24) / 255
                g = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255
                b = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255
                a = CGFloat(hexNumber & 0x000000FF) / 255
                self.init(red: r, green: g, blue: b, alpha: a)
                return
            }
        }
        
        return nil // If the string is not 6 or 8 characters long, return nil
    }
}

