/**
 
 # Experimenting with SKSpriteNode
 
 Created: 9 March 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct SpriteNodesPreview: View {
    var myScene = SpriteNodesScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                preferredFramesPerSecond: 120,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount, .showsPhysics]
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    SpriteNodesPreview()
}

// MARK: - SpriteKit

class SpriteNodesScene: SKScene {
    
    // MARK: Scene setup
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .lightGray
    }
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        scene?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        physicsWorld.speed = 1
        physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        /// comment/uncomment to execute various examples
        drawSprites()
    }
    
    // MARK: drawing sprites
    func drawSprites() {
        let concaveTexture = SKTexture(imageNamed: "concave_shape_1")
        let concaveSprite = SKSpriteNode(texture: concaveTexture)
        concaveSprite.physicsBody = SKPhysicsBody(texture: concaveTexture, size: concaveTexture.size())
        concaveSprite.position = CGPoint(x: 0, y: 300)
        addChild(concaveSprite)
        
        let chainTexture = SKTexture(imageNamed: "chain_sprite")
        let chainSprite = SKSpriteNode(texture: chainTexture)
        chainSprite.physicsBody = SKPhysicsBody(texture: chainTexture, alphaThreshold: 0.1, size: chainTexture.size())
        chainSprite.position = CGPoint(x: 0, y: 150)
        addChild(chainSprite)
        
        let effectNode = SKEffectNode()
        let ellipse = SKShapeNode(ellipseOf: CGSize(width: 100, height: 200))
        ellipse.lineWidth = 1
        ellipse.fillColor = .yellow
        if let path2 = ellipse.path {
            ellipse.physicsBody = SKPhysicsBody(polygonFrom: path2)
        }
        effectNode.addChild(ellipse)
        addChild(effectNode)
    }
    
}



