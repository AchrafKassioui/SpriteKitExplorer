/**
 
 # bmGlyph class
 
 This is Swift translation of the original Objective-C class BMGlyphLabel.m
 Source: https://github.com/tapouillo/BMGlyphLabel/blob/master/BMGlyphLabel/BMGlyphLabel.m
 The translation was done by Google Gemini
 
 I store the class here. I may use it for:
 - If I use custom bitmap fonts in TheTool
 - To learn how text can be composed from multiple letters, in order to implement proper physics bodies on strings of characters, because SpriteKit does not generate concave physics bodies for each character in a label.
 
 Achraf Kassioui
 Created: 21 April 2024
 Updated: 21 April 2024
 
 */

import SpriteKit

/*
class BMGlyphLabel: SKNode {
    // Properties
    var text: String = "" {
        didSet {
            updateLabel()
            justifyText()
        }
    }
    var horizontalAlignment: BMGlyphHorizontalAlignment = .centered {
        didSet { justifyText() }
    }
    var verticalAlignment: BMGlyphVerticalAlignment = .middle {
        didSet { justifyText() }
    }
    var textJustify: BMGlyphJustify = .left {
        didSet { justifyText() }
    }
    var font: BMGlyphFont?  // Assumed you have a BMGlyphFont class in Swift
    
    var color: SKColor = .white { // Default to white
        didSet {
            children.forEach { ($0 as? SKSpriteNode)?.color = color }
        }
    }
    var colorBlendFactor: CGFloat = 1.0 {
        didSet {
            colorBlendFactor = max(0.0, min(colorBlendFactor, 1.0)) // Clamp the value
            children.forEach { ($0 as? SKSpriteNode)?.colorBlendFactor = colorBlendFactor }
        }
    }
    
    private var totalSize: CGSize = .zero
    
    // Enums
    enum BMGlyphHorizontalAlignment {
        case centered, right, left
    }
    
    enum BMGlyphVerticalAlignment {
        case middle, top, bottom
    }
    
    enum BMGlyphJustify {
        case left, right, center
    }
    
    // Initializers
    convenience init(text: String, font: BMGlyphFont) {
        self.init()
        self.font = font
        self.text = text
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Text update and justification logic
    private func updateLabel() {
        guard let font = font else { return }
        
        let scaleFactor = UIScreen.main.scale // Adjust for screen resolution if needed
        
        var size = CGSize.zero
        var position = CGPoint.zero
        let lines = text.components(separatedBy: "\n")
        
        // Remove unused nodes
        let targetChildCount = text.count - lines.count + 1
        if children.count > targetChildCount {
            children[targetChildCount...].forEach { $0.removeFromParent() }
        }
        
        size.height += font.lineHeight / scaleFactor
        
        var realCharCount = 0
        for line in lines {
            for char in line {
                let texture = font.charsTextures["\(char)"]!
                
                let letter: SKSpriteNode
                if realCharCount < children.count {
                    letter = children[realCharCount] as! SKSpriteNode
                } else {
                    letter = SKSpriteNode(texture: texture)
                    addChild(letter)
                }
                
                let lastCharId = realCharCount > 0 ? line[line.index(before: line.startIndex)] : Character(" ") // Handle first character
                
                letter.color = color
                letter.colorBlendFactor = colorBlendFactor
                letter.anchorPoint = .zero
                letter.size = texture.size() // Set size based on the texture
                
                let xOffset = font.xOffset(char) + font.kerning(forFirst: lastCharId, second: char)
                let yOffset = font.yOffset(char)
                
                position.x += (font.xAdvance(char) + xOffset) / scaleFactor
                
                letter.position = CGPoint(
                    x: position.x,
                    y: position.y - (letter.size.height + yOffset / scaleFactor)
                )
                letter.userData = ["originalPosition": NSValue(cgPoint: letter.position)]
                
                size.width = max(size.width, position.x)
                realCharCount += 1
            }
            position.x = 0
            position.y -= font.lineHeight / scaleFactor
            size.height += font.lineHeight / scaleFactor
        }
        
        totalSize = size
    }
    
    private func justifyText() {
        var shift = CGPoint.zero
        
        switch horizontalAlignment {
            case .left:
                shift.x = 0
            case .right:
                shift.x = -totalSize.width
            case .centered:
                shift.x = -totalSize.width / 2
        }
        
        switch verticalAlignment {
            case .bottom:
                shift.y = -totalSize.height
            case .top:
                shift.y = 0
            case .middle:
                shift.y = -totalSize.height / 2
        }
        
        for child in children {
            guard let node = child as? SKSpriteNode,
                  let originalPositionValue = node.userData?["originalPosition"] as? NSValue else { continue }
            
            let originalPosition = originalPositionValue.cgPointValue
            node.position = CGPoint(
                x: originalPosition.x + shift.x,
                y: originalPosition.y - shift.y
            )
        }
        
        if textJustify != .left {
            var numberNodes = 0
            var nodePosition = 0
            var widthForLine = 0
            
            for i in 0...text.count {
                let c = i < text.count ? text[text.index(text.startIndex, offsetBy: i)] : "\n"
                
                if c == "\n" {
                    if numberNodes > 0 {
                        while nodePosition < numberNodes {
                            guard let node = children[nodePosition] as? SKSpriteNode else {
                                nodePosition += 1
                                continue
                            }
                            
                            if textJustify == .right {
                                node.position.x += totalSize.width - CGFloat(widthForLine) + shift.x
                            } else if textJustify == .center {
                                node.position.x += (totalSize.width - CGFloat(widthForLine)) / 2 + shift.x / 2
                            }
                            
                            nodePosition += 1
                        }
                    }
                    widthForLine = 0
                } else {
                    guard let node = children[numberNodes] as? SKSpriteNode else {
                        numberNodes += 1
                        continue
                    }
                    numberNodes += 1
                    widthForLine = Int(node.position.x + node.size.width)
                }
            }
        }
    }
    
}

class BMGlyphFont {
    let lineHeight: Int
    private let kernings: [String: Int]
    private let chars: [String: Int]
    let charsTextures: [String: SKTexture]
    private let textureAtlas: SKTextureAtlas
    
    init?(name: String) {
        lineHeight = 0
        kernings = [:]
        chars = [:]
        charsTextures = [:]
        
        let deviceSuffix = self.getSuffixForDevice()
        let fontFile = "\(name)\(deviceSuffix)"
        
        guard let path = Bundle.main.path(forResource: fontFile, ofType: "xml"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        
        textureAtlas = SKTextureAtlas(named: name)
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }
    
    private func getSuffixForDevice() -> String {
#if os(iOS) || os(tvOS)
        let scale = UIScreen.main.nativeScale
        if scale == 2.0 {
            return "@2x"
        } else if scale > 2.0 && scale <= 3.0 {
            return "@3x"
        }
#endif
        return ""
    }
    
    func xAdvance(_ charId: Character) -> Int {
        return chars["xadvance_\(Int(charId.unicodeScalars.first!.value))"] ?? 0
    }
    
    func xOffset(_ charId: Character) -> Int {
        return chars["xoffset_\(Int(charId.unicodeScalars.first!.value))"] ?? 0
    }
    
    func yOffset(_ charId: Character) -> Int {
        return chars["yoffset_\(Int(charId.unicodeScalars.first!.value))"] ?? 0
    }
    
    func kerning(forFirst first: Character, second: Character) -> Int {
        let key = "\(Int(first.unicodeScalars.first!.value))/\(Int(second.unicodeScalars.first!.value))"
        return kernings[key] ?? 0
    }
    
    func texture(for charId: Character) -> SKTexture? {
        let key = String(Int(charId.unicodeScalars.first!.value))
        return charsTextures[key]
    }
}

*/
