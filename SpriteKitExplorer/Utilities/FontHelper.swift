/**
 
 # Font Helper for SpriteKit
 
 Usage:
 
 ```
 let myLabel = SKLabelNode(text: "My text string")
 myLabel.fontName = FontHelpers.fontName(with: "Times New Roman", italic: true, bold: false)
 
 ```
 
 Created: 13 March 2024
 Credit: https://chsxf.dev/2023/08/27/13-working-with-fonts-in-spritekit.html
 
 */

import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

final class FontHelper {
    
    class func fontName(with fontFamily: String, italic: Bool, bold: Bool) -> String? {
        getFontName(fontFamily, italic, bold)
    }
    
#if os(macOS)
    
    fileprivate class func getFontName(_ fontFamily: String, _ italic: Bool, _ bold: Bool) -> String? {
        var traits: NSFontTraitMask = []
        if italic {
            traits.insert(.italicFontMask)
        }
        if bold {
            traits.insert(.boldFontMask)
        }
        let font = NSFontManager.shared.font(withFamily: fontFamily, traits: traits, weight: 5, size: 12)
        return font?.fontName
    }
    
#else
    
    fileprivate class func getFontName(_ fontFamily: String, _ italic: Bool, _ bold: Bool) -> String? {
        var descriptor = UIFontDescriptor().withFamily(fontFamily)
        if bold || italic {
            var traits: UIFontDescriptor.SymbolicTraits = []
            if italic {
                traits.insert(.traitItalic)
            }
            if bold {
                traits.insert(.traitBold)
            }
            if let newDescriptor = descriptor.withSymbolicTraits(traits) {
                descriptor = newDescriptor
            }
        }
        let font = UIFont(descriptor: descriptor, size: 12)
        return font.fontName
    }
    
#endif
    
}
