/**
 
 # Compound Physics Bodies
 
 See: https://github.com/AchrafKassioui/Learning-SpriteKit/tree/main?tab=readme-ov-file#compound-physics-bodies
 
 Achraf Kassioui
 Created 7 November 2024
 updated 7 November 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

struct CompoundBodyView: View {
    var myScene = CompoundBodyScene()
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene
                ,debugOptions: [.showsPhysics]
            )
            .ignoresSafeArea()
        }
        .background(Color(SKColor.black))
    }
}

#Preview {
    CompoundBodyView()
}

class CompoundBodyScene: SKScene {
    
    // MARK: Scene Setup
    
    let fillColor = SKColor(white: 0, alpha: 0.3)
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        physicsWorld.gravity = CGVector(dx: 0, dy: -10)
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        
        let inertialCamera = InertialCamera(scene: self)
        self.camera = inertialCamera
        addChild(inertialCamera)
        
        let sprite = SKSpriteNode(color: fillColor, size: CGSize(width: 10, height: 200))
        sprite.name = "sprite"
        sprite.position = CGPoint(x: 0, y: 200)
        /// We use the `center` parameter to position the body in the compound body
        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size, center: sprite.position)
        sprite.physicsBody?.isDynamic = false
        addChild(sprite)
        
        let shape = SKSpriteNode(color: fillColor, size: CGSize(width: 60, height: 30))
        shape.name = "shape"
        shape.position = CGPoint(x: 0, y: 315)
        shape.physicsBody = SKPhysicsBody(rectangleOf: shape.size, center: shape.position)
        shape.physicsBody?.isDynamic = false
        addChild(shape)
        
        let label = SKLabelNode(text: "Compound")
        label.position = CGPoint(x: 0, y: 80)
        /// The rotation isn't reflected in the body added to the compound boy
        label.zRotation = -0.2
        label.fontName = "MenloBold"
        label.fontSize = 24
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.physicsBody = SKPhysicsBody(rectangleOf: label.frame.size, center: label.position)
        label.physicsBody?.isDynamic = false
        addChild(label)
        
        let compound = SKSpriteNode(color: .clear, size: CGSize(width: 50, height: 50))
        compound.position = CGPoint(x: 0, y: 0)
        compound.physicsBody = SKPhysicsBody(bodies: [sprite.physicsBody!, shape.physicsBody!, label.physicsBody!])
        addChild(compound)
        
        let ground = SKSpriteNode(color: .black, size: CGSize(width: 1000, height: 10))
        ground.position.y = -400
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        addChild(ground)
    }
}
