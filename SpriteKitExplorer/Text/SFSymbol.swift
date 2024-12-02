/**
 
 # SF Symbol in SpriteKit
 
 Achraf Kassioui
 Created 19 November 2024
 Updated 19 November 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

/// The main SwiftUI view
struct SFSymbolView: View {
    let myScene = SFSymbolScene()
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene
                ,debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount, .showsQuadCount, .showsFields, .showsFields, .showsPhysics]
            )
            .ignoresSafeArea()
            VStack {
                Spacer()
                SWUIScenePauseButton(scene: myScene, isPaused: false)
            }
        }
        .background(Color(SKColor.black))
    }
}

#Preview {
    SFSymbolView()
}

class SFSymbolScene: SKScene {
    
    // MARK: Scene Setup
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        let icon = generateSpriteFromSFSymbol(symbolName: "arrowtriangle.right.fill", color: .white, size: CGSize(width: 32, height: 32))
        addChild(icon)
    }
    
    // MARK: Update
    
    override func update(_ currentTime: TimeInterval) {
        
    }
    
    // MARK: Touch
    
    var touchedNodes = [UITouch:SKNode]()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            let touchedNode = atPoint(touchLocation)
            if touchedNode.name == "sprite" {
                touchedNodes[touch] = touchedNode
                
                touchedNode.physicsBody?.isDynamic = false
                touchedNode.physicsBody?.velocity = .zero
                touchedNode.physicsBody?.angularVelocity = 0
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let node = touchedNodes[touch] {
                let touchLocation = touch.location(in: self)
                node.position = touchLocation
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let node = touchedNodes[touch] {
                node.physicsBody?.isDynamic = true
                touchedNodes.removeValue(forKey: touch)
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}

// MARK: Create SF Symbol

func generateSpriteFromSFSymbol(symbolName: String, color: SKColor, size: CGSize, weight: UIImage.SymbolWeight = .regular) -> SKSpriteNode {
    let configuration = UIImage.SymbolConfiguration(pointSize: size.width, weight: weight)
    
    /// Generate the symbol with the configuration
    if let sfSymbol = UIImage(systemName: symbolName, withConfiguration: configuration)?.withTintColor(color) {
        /// Convert the symbol to PNG data and back to a UIImage
        /// It seems I need this step to apply a color to the generated sprite
        if let pngData = sfSymbol.pngData(), let image = UIImage(data: pngData) {
            return SKSpriteNode(texture: SKTexture(image: image), size: size)
        }
    }
    /// If no SF Symbol is found, this is the placeholder sprite we return
    return SKSpriteNode(color: color, size: size)
}
