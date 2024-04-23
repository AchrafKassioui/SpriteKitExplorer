/**
 
 # UI and helper methods for the camera experimentations
 
 Achraf Kassioui
 Created: 8 April 2024
 Updated: 8 April 2024
 
 */

import SpriteKit

// MARK: Button class

class ButtonWithIconAndPattern: SKShapeNode {
    
    /// a call back function to execute
    /// the function to execute is passed as an argument during initialization
    let onTouch: () -> Void
    
    enum ButtonState {
        case base
        case active
    }
    
    private var buttonState: ButtonState = .base
    private let iconName1: String
    private let iconName2: String
    
    private let icon: SKSpriteNode
    
    /// initialization
    init(
        size: CGSize,
        icon1: String,
        icon2: String,
        iconSize: CGSize,
        onTouch: @escaping () -> Void
    ) {
        self.onTouch = onTouch
        self.iconName1 = icon1
        self.iconName2 = icon2
        
        /// button icon
        self.icon = SKSpriteNode(imageNamed: icon1)
        self.icon.size = iconSize
        self.icon.colorBlendFactor = 1
        self.icon.color = SKColor(white: 0, alpha: 1)
        self.icon.isUserInteractionEnabled = false
        
        /// button shape
        super.init()
        self.path = CGPath(ellipseIn: CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size), transform: nil)
        
        /// styling
        let dotTexture = generateDotPatternImage(size: size)
        fillTexture = dotTexture
        strokeColor = SKColor(white: 0, alpha: 1)
        fillColor = SKColor(white: 1, alpha: 0.4)
        
        isUserInteractionEnabled = true
        addChild(icon)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// initialization
    private func updateIcon() {
        let iconName = buttonState == .base ? iconName1 : iconName2
        let iconColor: SKColor = buttonState == .base ? SKColor(white: 0, alpha: 1) : SKColor.systemRed
        icon.texture = SKTexture(imageNamed: iconName)
        icon.color = iconColor
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        buttonState = buttonState == .base ? .active : .base
        updateIcon()
        onTouch()
    }
    
}
