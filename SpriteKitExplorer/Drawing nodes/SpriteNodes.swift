/**
 
 # Experimenting with SKSpriteNode
 
 Created: 9 March 2024
 Updated: 17 March 2024
 
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
                debugOptions: [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount]
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    SpriteNodesPreview()
}

// MARK: - Scene setup

class SpriteNodesScene: SKScene {
    
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
    }
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        scene?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        physicsWorld.speed = 1
        physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        let cameraNode = InertialCamera(scene: self)
        addChild(cameraNode)
        camera = cameraNode
        
        /// comment/uncomment to execute various examples
        //drawSprites()
        drawSpriteWithShadow()
    }
    
    // MARK: - Shadow sprite
    
    func drawSpriteWithShadow() {
        let background = SKSpriteNode(imageNamed: "abstract-dunes-1024")
        background.setScale(2.4)
        background.texture?.filteringMode = .nearest
        background.zPosition = -1
        //addChild(background)
        
        let shadowTexture = generateShadowTexture(
            width: 60,
            height: 180,
            cornerRadius: 12,
            shadowOffset: CGSize( width: 0, height: 4),
            shadowBlurRadius: 20,
            shadowColor: SKColor(white: 0, alpha: 0.6)
        )
        
        let shadowSprite = SKSpriteNode(texture: shadowTexture)
        shadowSprite.position.y = -5
        shadowSprite.zPosition = 10
        shadowSprite.blendMode = .multiplyAlpha
        addChild(shadowSprite)
    }
    
    // MARK: - drawing sprites
    
    func drawSprites() {
        /// apply a Core Image filter to the texture
        /// pass one of the premade filters below to the SKTexture function
        let farfalleTexture = SKTexture(imageNamed: "concave_shape_1").applying(MyFilters.dither(intensity: 1))
        let farfalleSprite = SKSpriteNode(texture: farfalleTexture)
        farfalleSprite.physicsBody = SKPhysicsBody(texture: farfalleTexture, size: farfalleTexture.size())
        farfalleSprite.position = CGPoint(x: 0, y: 300)
        addChild(farfalleSprite)
        
        /// a sprite made from a texture with some thin parts
        /// used to test if physics body will conform to the most thinner parts of the texture
        let chainTexture = SKTexture(imageNamed: "chain_sprite")
        let chainSprite = SKSpriteNode(texture: chainTexture)
        chainSprite.physicsBody = SKPhysicsBody(texture: chainTexture, size: chainTexture.size())
        chainSprite.position = CGPoint(x: 0, y: 150)
        addChild(chainSprite)
        
        /// a very concave texture to stress test physics body generation
        let concaveTexture = SKTexture(imageNamed: "edge_shape_2")
        let concaveSprite = SKSpriteNode(texture: concaveTexture, size: concaveTexture.size())
        concaveSprite.color = SKColor.white.withAlphaComponent(1)
        concaveSprite.colorBlendFactor = 1
        concaveSprite.physicsBody = SKPhysicsBody(texture: concaveTexture, size: concaveTexture.size())
        concaveSprite.physicsBody?.density = 100
        addChild((concaveSprite))
    }
    
}



