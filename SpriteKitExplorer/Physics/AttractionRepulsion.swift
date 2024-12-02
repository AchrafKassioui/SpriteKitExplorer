/**
 
 # SpriteKit Attraction and Repulsion
 
 Achraf Kassioui
 Created 18 November 2024
 Updated 18 November 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

/// The main SwiftUI view
struct AttractionRepulsionView: View {
    let myScene = AttractionRepulsionScene()
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene
                ,debugOptions: [.showsNodeCount, .showsFPS, .showsFields, .showsPhysics]
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
    AttractionRepulsionView()
}

class AttractionRepulsionScene: SKScene {
    
    // MARK: Scene Setup
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        cleanPhysics()
        
        createBodiesWithCharges(amount: 1)
        
        let action = SKAction.customAction(withDuration: 30/60) { node, elapsedTime in
            //if let node = self.childNode(withName: "//sprite") {
                //node.physicsBody?.applyImpulse(CGVector(dx: 10, dy: 10))
            //}
        }
        run(action)
    }
    
    func createBodiesWithCharges(amount: Int) {
        for i in 1...amount {
            let sprite = SKSpriteNode(texture: SKTexture(imageNamed: "rectangle-60-20-fill"))
            sprite.position = CGPoint(x: 0, y: CGFloat(2*i) + sprite.size.height)
            sprite.name = "sprite"
            sprite.colorBlendFactor = 1
            sprite.color = .systemYellow
            sprite.physicsBody = SKPhysicsBody(texture: sprite.texture!, size: sprite.texture!.size())
            sprite.physicsBody?.linearDamping = 10
            sprite.physicsBody?.allowsRotation = false
            sprite.physicsBody?.charge = 1
            sprite.setScale(1)
            let _ = SKConstraint.positionX(
                SKRange(lowerLimit: -150, upperLimit: 150),
                y: SKRange(lowerLimit: -400, upperLimit: 400)
            )
            sprite.constraints = [createConstraintsInView(view: self.view!, node: sprite, region: .view)]
            addChild(sprite)
            
            let field = SKFieldNode.electricField()
            field.region = SKRegion(radius: 80)
            field.minimumRadius = 60
            field.strength = 0.1
            field.falloff = -1
            sprite.addChild(field)
        }
    }
    
    // MARK: Gravity Field
    /**
     
     Use a for loop to create as many of these objects.
     Reversing the field strength sign makes the bodies attract or repel each other.
     Make sure to adjust the region radius depending on the sprite size.
     It works well, but multiplying the fields impacts the framerate. I find that specfiying a field region is what impacts performance the most.
     
     */
    func createBodiesWithOwnGravity(amount: Int) {
        for _ in 1...amount {
            let sprite = SKSpriteNode(texture: SKTexture(imageNamed: "rectangle-60-20-fill"))
            sprite.name = "sprite"
            sprite.colorBlendFactor = 1
            sprite.color = .systemYellow
            sprite.physicsBody = SKPhysicsBody(texture: sprite.texture!, size: sprite.texture!.size())
            sprite.physicsBody?.linearDamping = 10
            sprite.physicsBody?.allowsRotation = false
            sprite.setScale(1)
            addChild(sprite)
            
            let field = SKFieldNode.radialGravityField()
            field.region = SKRegion(radius: 80) /// The bigger the radius, the farther sprites affect each other
            field.strength = -10
            field.falloff = 0
            sprite.addChild(field)
        }
    }
    
    // MARK: Update
    
    override func update(_ currentTime: TimeInterval) {
        
    }
    
    // MARK: Touch
    
    var touchedNodes = [UITouch:SKNode]()
    var touchOffsets = [SKNode: CGPoint]()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            let touchedNode = atPoint(touchLocation)
            if touchedNode.name == "sprite" {
                touchedNodes[touch] = touchedNode
                touchOffsets[touchedNode] = touchLocation - touchedNode.position
                
                touchedNode.physicsBody?.isDynamic = false
                touchedNode.physicsBody?.velocity = .zero
                touchedNode.physicsBody?.angularVelocity = 0
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let node = touchedNodes[touch], let offset = touchOffsets[node] {
                let touchLocation = touch.location(in: self)
                node.position = touchLocation - offset
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let node = touchedNodes[touch] {
                node.physicsBody?.isDynamic = true
                touchedNodes.removeValue(forKey: touch)
                touchOffsets[node] = .zero
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
