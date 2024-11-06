/**
 
 # Converting to Scene Coordinates
 
 Get the absolute scene coordinates of any node regardless of its nesting within the graph hierarchy.
 
 Achraf Kassioui
 Created 6 November 2024
 updated 6 November 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

/// The main SwiftUI view
struct SceneCoordinatesView: View {
    var myScene = SceneCoordinatesScene()
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount, .showsQuadCount, .showsPhysics]
            )
            .ignoresSafeArea()
        }
        /// Using the `SKColor` type, in case we want to reference a SpriteKit color in SwiftUI
        .background(Color(SKColor.black))
    }
}

#Preview {
    SceneCoordinatesView()
}

class SceneCoordinatesScene: SKScene {
    
    // MARK: Scene Setup
    
    let fillColor = SKColor(white: 0, alpha: 0.3)
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        physicsWorld.gravity = CGVector(dx: 0, dy: -10)
        
        let inertialCamera = InertialCamera(scene: self)
        self.camera = inertialCamera
        addChild(inertialCamera)
        
        let sprite = SKSpriteNode(color: fillColor, size: CGSize(width: 10, height: 200))
        sprite.name = "sprite"
        sprite.position = CGPoint(x: -100, y: 0)
        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        addChild(sprite)
        
        let childSprite = SKSpriteNode(color: fillColor, size: CGSize(width: 60, height: 30))
        childSprite.name = "childSprite"
        childSprite.position = CGPoint(x: 0, y: sprite.size.height / 2 + childSprite.size.height / 2)
        childSprite.physicsBody = SKPhysicsBody(rectangleOf: childSprite.size)
        sprite.addChild(childSprite)
        
        let nestedSprite = SKSpriteNode(color: fillColor, size: CGSize(width: 40, height: 40))
        nestedSprite.name = "nestedSprite"
        nestedSprite.position = CGPoint(x: 200, y: childSprite.size.height / 2 + nestedSprite.size.height / 2)
        nestedSprite.physicsBody = SKPhysicsBody(rectangleOf: nestedSprite.size)
        childSprite.addChild(nestedSprite)
        
        let ground = SKSpriteNode(color: .black, size: CGSize(width: 1000, height: 10))
        ground.position.y = -300
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        addChild(ground)
    }
    
    // MARK: Touch
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            /// Note that `atPoint` does hit detection using the accumulated frame of the touched node, which includes its children.
            //let touchedNode = atPoint(touch.location(in: self))
            
            /// Use physics for more accurate hit detection
            let touchedBody = physicsWorld.body(at: touch.location(in: self))
            guard let touchedNode = touchedBody?.node else { return }
            
            if let parent = touchedNode.parent {
                let positionInScene = convert(touchedNode.position, from: parent)
                print("")
                print("\(touchedNode.name ?? "") parent is \(parent)")
                print("\(touchedNode.name ?? "") position in parent \(touchedNode.position)")
                print("\(touchedNode.name ?? "") position in scene \(positionInScene)")
                touchedNode.removeAllActions()
                let action1 = SKAction.colorize(with: .systemRed, colorBlendFactor: 1, duration: 0)
                let action2 = SKAction.colorize(with: fillColor, colorBlendFactor: 1, duration: 0)
                let sequence = SKAction.sequence([action1, SKAction.wait(forDuration: 0.1), action2])
                touchedNode.run(sequence)
            }
        }
    }
}
