/**
 
 # SpriteKit Constraints
 
 Achraf Kassioui
 Created 20 November 2024
 Updated 20 November 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

/// The main SwiftUI view
struct ConstraintsPlaygroundView: View {
    let myScene = ConstraintsPlaygroundScene()
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount, .showsQuadCount, .showsFields]
            )
            .ignoresSafeArea()
            VStack {
                Spacer()
                SWUIScenePauseButton(scene: myScene, isPaused: false)
            }
        }
        .background(Color(SKColor.black))
        .persistentSystemOverlays(.hidden)
    }
}

#Preview {
    ConstraintsPlaygroundView()
}

class ConstraintsPlaygroundScene: SKScene {
    
    // MARK: Scene Setup
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        
        cleanPhysics()
        
        createConstraintsForDraggedNodes(view: view)
    }
    
    func createConstraintsForDraggedNodes(view: SKView) {
        physicsWorld.gravity = .zero
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        let texture = SKTexture(imageNamed: "rectangle-60-20-fill")
        let lockToCenter = SKConstraint.positionX(
            SKRange(lowerLimit: -view.bounds.width/2, upperLimit: view.bounds.width/2),
            y: SKRange(lowerLimit: -view.bounds.height/2, upperLimit: view.bounds.height/2)
        )
        
        for _ in 1...100 {
            let sprite = DraggableSpriteWithVelocity(texture: texture, color: .systemYellow, size: texture.size())
            sprite.name = "DraggableSpriteWithPhysics NaNCandidate"
            sprite.physicsBody = SKPhysicsBody(texture: texture, size: texture.size())
            sprite.physicsBody?.charge = -1
            sprite.setScale(0.25)
            sprite.constraints = [ lockToCenter ]
            addChild(sprite)
        }
        
        let field = SKFieldNode.electricField()
        field.position = CGPoint(x: -1, y: -1)
        field.minimumRadius = 10
        //field.region = SKRegion(radius: 100)
        field.strength = 1
        addChild(field)
        
        let field2 = SKFieldNode.magneticField()
        //field2.region = SKRegion(radius: 100)
        field2.strength = 1
        addChild(field2)
    }
    
    /// Adaptation of https://developer.apple.com/documentation/spritekit/skconstraint/creating_a_look-at_constraint
    func createOrientationConstraints(view: SKView) {
        let target = SKShapeNode(circleOfRadius: 30)
        target.physicsBody = SKPhysicsBody(circleOfRadius: 30)
        target.physicsBody?.charge = -1
        target.zPosition = 10
        target.fillColor = .systemYellow
        target.strokeColor = SKColor(white: 0, alpha: 0.3)
        target.name = "draggable NaNCandidate"
        target.position = CGPoint(x: 0, y: 0)
        addChild(target)

        let lockToCenter = SKConstraint.positionX(
            SKRange(lowerLimit: -view.bounds.width/2, upperLimit: view.bounds.width/2),
            y: SKRange(lowerLimit: -view.bounds.height/2, upperLimit: view.bounds.height/2)
        )
        
        target.constraints = [ lockToCenter ]
        
        let label = SKLabelNode(text: "Target")
        label.position.y = 40
        label.fontName = "Menlo"
        label.fontSize = 16
        target.addChild(label)
        
        let pointer = SKSpriteNode(imageNamed: "arrowshape.right.fill")
        pointer.position = CGPoint(x: 0, y: 0)
        pointer.colorBlendFactor = 1
        pointer.color = SKColor(white: 1, alpha: 0.6)
        addChild(pointer)
        
        let lookAtConstraint = SKConstraint.orient(to: target, offset: SKRange(constantValue: 0))
        //let limitLookAt = SKConstraint.zRotation(SKRange(lowerLimit: 0, upperLimit: .pi))
        
        pointer.constraints = [ lookAtConstraint ]
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        let field = SKFieldNode.noiseField(withSmoothness: 0, animationSpeed: 1)
        field.strength = 10
        addChild(field)
    }
    
    /// Adaptation of https://developer.apple.com/documentation/spritekit/skconstraint/creating_position_constraints
    func createBasicPositionConstraints() {
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        let noiseField = SKFieldNode.noiseField(withSmoothness: 1, animationSpeed: 0.1)
        addChild(noiseField)
        
        let shape = SKShapeNode(circleOfRadius: 30)
        shape.fillColor = .systemYellow
        shape.strokeColor = SKColor(white: 0, alpha: 0.6)
        shape.lineWidth = 2
        shape.physicsBody = SKPhysicsBody(circleOfRadius: 30)
        addChild(shape)
        
        let lockToCenter = SKConstraint.positionX(
            SKRange(lowerLimit: -150, upperLimit: 150),
            y: SKRange(lowerLimit: -400, upperLimit: 400)
        )
        
        shape.constraints = [ lockToCenter ]
    }
    
    // MARK: Update
    
    override func update(_ currentTime: TimeInterval) {
        /// Used by instances of `DraggableSpriteWithVelocity`
        enumerateChildNodes(withName: "//*DraggableSpriteWithPhysics*", using: { node, _ in
            if let node = node as? DraggableSpriteWithVelocity {
                node.update(currentTime: currentTime)
                node.physicsBody?.applyAngularImpulse(0.001)
            }
        })
        
        /// Sometimes, a physics simulation would make a node disappear from the screen. Even constraints can't hold it in.
        /// Logging the disappearing node position returns a NaN value for x and y.
        /// This enumeration checks if the position is absurd, and brings the node back into view.
        enumerateChildNodes(withName: "//*NaNCandidate*", using: { node, stop in
            if node.position.x.isNaN || node.position.y.isNaN {
                print("position is absurd")
                node.physicsBody?.velocity = .zero
                node.physicsBody?.angularVelocity = 0
                node.position = CGPoint(x: 150, y: 300)
            }
        })
    }
    
    // MARK: Touch
    
    var touchedNodes = [UITouch:SKNode]()
    var touchOffsets = [SKNode: CGPoint]()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            let touchedNode = atPoint(touchLocation)
            if touchedNode.name == "draggable" {
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
                touchedNodes.removeValue(forKey: touch)
                touchOffsets[node] = .zero
                node.physicsBody?.isDynamic = true
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
