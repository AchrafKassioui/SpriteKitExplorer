/**
 
 # SpriteKit Electris and Magnetic Fields
 
 Experimenting with electric and magnetic SKFieldNode
 
 Achraf Kassioui
 Created 20 November 2024
 Updated 20 November 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

struct EMFieldsView: View {
    let myScene: SKScene = EMFieldsScene()
    @State private var isPaused: Bool = true
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene
                ,debugOptions: [.showsQuadCount, .showsNodeCount, .showsFPS]
            )
            .ignoresSafeArea()
            VStack {
                Spacer()
                SWUIScenePauseButton(scene: myScene, isPaused: isPaused)
            }
        }
        .background(Color(SKColor.black))
        .persistentSystemOverlays(.hidden)
    }
}

#Preview {
    EMFieldsView()
}

class EMFieldsScene: SKScene {
    
    // MARK: Scene Setup
    
    override func didMove(to view: SKView) {
        isPaused = true
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        
        cleanPhysics()
        
        let inertialCamera = InertialCamera(scene: self)
        camera = inertialCamera
        addChild(inertialCamera)
        
        CreateEMField(view: view)
    }
    
    func CreateEMField(view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        /// Play with physics speed
        physicsWorld.speed = 1
        
        let circleRadius: CGFloat = 240
        let circle = SKShapeNode(circleOfRadius: circleRadius)
        circle.lineWidth = 6
        circle.strokeColor = SKColor(white: 0, alpha: 0.8)
        circle.fillColor = SKColor(white: 1, alpha: 0.2)
        circle.physicsBody = SKPhysicsBody(edgeLoopFrom: circle.path!)
        addChild(circle)
        
        let texture = SKTexture(imageNamed: "circle-30-fill")
        
        /// Change the number of spawned circles
        for i in 1...200 {
            let sprite = DraggableSpriteWithVelocity(texture: texture, color: .white, size: texture.size())
            sprite.name = "DraggableSpriteWithPhysics NaNCandidate"
            sprite.physicsBody = SKPhysicsBody(circleOfRadius: 30)
            sprite.physicsBody?.charge = -1
            sprite.physicsBody?.density = 0.1
            sprite.setScale(0.1)
            
            /// Add a distance constraint to keep the sprite within the circle
            let centerPoint = CGPoint(x: 0, y: 0) /// Circle's center
            let lockToCircle = SKConstraint.distance(SKRange(upperLimit: circleRadius - 6), to: centerPoint)
            sprite.constraints = [lockToCircle]
            
            /// Change the interval between spawn
            run(SKAction.wait(forDuration: Double(i) * 0.01)) {
                self.addChild(sprite)
            }
        }
        
        //let region = SKRegion(radius: 100)
        let falloff: Float = 0
        /// Positioning the field away from `.zero` prevents the simulation from producing NaN velocities
        let safePosition = CGPoint(x: -1, y: -1)
        
        let eField = SKFieldNode.electricField()
        eField.position = safePosition
        eField.minimumRadius = 100
        eField.falloff = falloff
        //eField.region = region
        eField.strength = 5
        addChild(eField)
        
        let mField = SKFieldNode.magneticField()
        mField.position = safePosition
        mField.minimumRadius = 100
        //mField.region = region
        mField.strength = 0.1
        addChild(mField)
    }
    
    // MARK: Electric Containement Field
    
    func CreateElectricContainementField(view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        /// Play with physics speed
        physicsWorld.speed = 1
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        let texture = SKTexture(imageNamed: "circle-30-fill")
        
        /// Change the number of spawned circles
        for i in 1...500 {
            let sprite = DraggableSpriteWithVelocity(texture: texture, color: .systemYellow, size: texture.size())
            sprite.position = CGPoint(x: view.bounds.width/CGFloat(i)/2, y: view.bounds.height/2 / CGFloat(i))
            sprite.name = "DraggableSpriteWithPhysics NaNCandidate"
            sprite.physicsBody = SKPhysicsBody(circleOfRadius: 30)
            sprite.physicsBody?.charge = -1
            sprite.setScale(0.25)
            
            let lockToCenter = SKConstraint.positionX(
                SKRange(lowerLimit: -view.bounds.width/2, upperLimit: view.bounds.width/2),
                y: SKRange(lowerLimit: -view.bounds.height/2, upperLimit: view.bounds.height/2)
            )
            sprite.constraints = [ lockToCenter ]
            
            /// Change the interval between spawn
            run(SKAction.wait(forDuration: Double(i) * 0.02)) {
                self.addChild(sprite)
            }
        }
        
        //let region = SKRegion(radius: 100)
        let falloff: Float = 0
        /// Positioning the field away from `.zero` prevents the simulation from producing NaN velocities
        let safePosition = CGPoint(x: -1, y: -1)
        
        let eField = SKFieldNode.electricField()
        eField.position = safePosition
        eField.minimumRadius = 100
        eField.falloff = falloff
        //eField.region = region
        eField.strength = 10
        addChild(eField)
    }
    
    // MARK: Update
    
    override func update(_ currentTime: TimeInterval) {
        /// Used by instances of `DraggableSpriteWithVelocity`
        enumerateChildNodes(withName: "//*DraggableSpriteWithPhysics*", using: { node, _ in
            if let node = node as? DraggableSpriteWithVelocity {
                node.update(currentTime: currentTime)
                //node.physicsBody?.applyAngularImpulse(0.001)
            }
        })
        
        /// Sometimes, a physics simulation would make a node disappear from the screen. Even constraints can't hold it in.
        /// Logging the disappearing node position returns a NaN value for x and y.
        /// This enumeration checks if the position is NaN, and brings back the node into view.
        enumerateChildNodes(withName: "//*NaNCandidate*", using: { node, stop in
            if node.position.x.isNaN || node.position.y.isNaN {
                print("position is absurd")
                node.physicsBody?.velocity = .zero
                node.physicsBody?.angularVelocity = 0
                node.position = CGPoint(x: 1, y: 1)
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
