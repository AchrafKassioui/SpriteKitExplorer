/**
 
 # A SKColor extension to support Hex values
 
 This SKColor extension allows you to use Hex colors with SpriteKit.
 Note that you can convert this extension to UIColor, by replacing any occurence of `SKColor` with `UIColor`
 SKColor itself is a type alias that abstracts over UIColor in iOS and NSColor in macOS, allowing you to write platform-independent code.
 
 The extension requires that you import a framework that understands SKColor, such as SpriteKit.
 If you convert the extension to UIColor, import a framework that understands UIColor.
 
 Usage:
 
 ```
 guard let myColor = UIColor(hex: "e10000") else { print("Hex color does not exist"); return }
 
 ```
 
 Created: 12 March 2024
 Updated: 13 March 2024
 Credit: https://www.hackingwithswift.com/example-code/uicolor/how-to-convert-a-hex-color-to-a-uicolor
 Edited to accept opaque and transparent Hex colors, and strings with or without a # prefix.
 
 */

import SpriteKit

extension SKColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        let start: String.Index
        
        /// adapt to string values that begin with #
        if hex.hasPrefix("#") {
            start = hex.index(hex.startIndex, offsetBy: 1)
        } else {
            start = hex.startIndex
        }
        
        let hexColor = String(hex[start...])
        
        /// for hex values such as `e10000`
        if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000FF) / 255
                /// if the hex value is 6 characters long, default to fully opaque
                a = 1.0
                self.init(red: r, green: g, blue: b, alpha: a)
                return
            }
        /// for hex values such as `e1000055`, the last 2 characters being the alpha value
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
        
        /// if the string is not 6 or 8 characters long, return nil
        print("Hex color value is not valid"); return nil
    }
}


