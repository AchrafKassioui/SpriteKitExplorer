/**
 
 # Indication Arrow
 
 A flashing arrow used to indicate things on screen
 
 Created: 26 April 2024
 Updated: 26 April 2024
 
 */

import SpriteKit

class IndicationArrow: SKSpriteNode {
    
    init(angle: CGFloat, color: SKColor) {
        let texture = SKTexture(imageNamed: "arrowshape.right.fill")
        super.init(texture: texture, color: .clear, size: texture.size())
        self.name = "draggable"
        self.zRotation = angle
        self.colorBlendFactor = 1
        self.color = color
        self.userData = ["animation": animation]
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let animation = SKAction.sequence([
        SKAction.fadeIn(withDuration: 0),
        SKAction.wait(forDuration: 0.5),
        SKAction.fadeAlpha(to: 0.1, duration: 0.4)
    ])
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            self.removeAllActions() // Stop any ongoing actions
            self.alpha = 1 // Reset to fully visible
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            if let flashAction = self.userData?["animation"] as? SKAction {
                self.run(SKAction.repeat(flashAction, count: 3))
            }
        }
    }
    
}
