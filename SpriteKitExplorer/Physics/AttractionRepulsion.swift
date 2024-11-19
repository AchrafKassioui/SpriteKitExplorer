/**
 
 # SpriteKit Boilerplate
 
 Achraf Kassioui
 Created 18 November 2024
 Updated 18 November 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

/// The main SwiftUI view
struct AttractionRepulsionView: View {
    var myScene = AttractionRepulsionScene()
    @State private var isPaused: Bool = false
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount, .showsQuadCount, .showsFields, .showsFields]
            )
            .ignoresSafeArea()
            VStack {
                Spacer()
                SWUIRoundButton(scene: myScene)
            }
        }
        .background(Color(SKColor.black))
    }
}

#Preview {
    AttractionRepulsionView()
}

class AttractionRepulsionScene: SKScene {
    
    // MARK: Scene Setup
    
    //var sprite = SKSpriteNode()
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        createChargedBodies()
        createChargedBodies()
    }
    
    func createChargedBodies() {
        let sprite = SKSpriteNode(texture: SKTexture(imageNamed: "rectangle-60-20-fill"))
        sprite.name = "sprite"
        sprite.colorBlendFactor = 1
        sprite.color = .systemYellow
        sprite.physicsBody = SKPhysicsBody(texture: sprite.texture!, size: sprite.texture!.size())
        sprite.physicsBody?.charge = 10
        addChild(sprite)
        
        let field = SKFieldNode.radialGravityField()
        field.region = SKRegion(radius: 100)
        field.strength = -3
        field.falloff = 0
        //field.minimumRadius = 30
        //field.physicsBody = SKPhysicsBody(circleOfRadius: 30)
        sprite.addChild(field)
    }
    
    // MARK: Update
    
    override func update(_ currentTime: TimeInterval) {
    }
    
    // MARK: Touch
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            let touchedNode = atPoint(touchLocation)
            if touchedNode.name == "//sprite" {
                
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            let touchedNode = atPoint(touchLocation)
            if touchedNode.name == "sprite" {
                touchedNode.position = touchLocation
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
