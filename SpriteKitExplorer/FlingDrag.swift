/**
 
 # Drag Node
 
 A basic setup for throwing object with inertia.
 Drag and throw the ball to try. The inertia after release uses physics.
 Uses SpriteKit touch event handling abd the update loop. Does not use UIKit gesture recognizer
 
 Drawbacks:
 - Uses a hardcoded framerate value to calculate the time the object took to travel a distance.
 - Assumes the object has a physicsBody, and overwrites its velocity.
 
 Created: 26 January 2024
 
 */

import UIKit
import SwiftUI
import SpriteKit
import Observation

// MARK: - SwiftUI

struct FlingDrag: View {
    @State var myScene = FlingDragScene()
    
    var body: some View {
        ZStack {
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
}

// MARK: - SpriteKit

@Observable class FlingDragScene: SKScene {
    
    var anObject: SKShapeNode!
    
    // MARK: Scene
    
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .lightGray
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        createObjects()
    }
    
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        setupPhysicsBoundaries()
    }
    
    func setupPhysicsBoundaries() {
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        borderBody.friction = 0
        borderBody.restitution = 0.5
        self.physicsBody = borderBody
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        setupPhysicsBoundaries()
    }
    
    // MARK: Objects
    
    func createObjects() {
        let objectRadius: CGFloat = 40
        anObject = SKShapeNode(circleOfRadius: objectRadius)
        anObject.fillColor = .systemOrange
        anObject.strokeColor = .black
        anObject.name = "draggable"
        anObject.zPosition = 10
        anObject.position = CGPoint(x: 0, y: 0)
        anObject.physicsBody = SKPhysicsBody(circleOfRadius: objectRadius)
        anObject.physicsBody?.linearDamping = 0
        addChild(anObject)
        
        let instructionsText = SKLabelNode(text: "Drag and throw the ball")
        instructionsText.fontName = "Menlo-Bold"
        instructionsText.fontSize = 24
        instructionsText.fontColor = SKColor(white: 1, alpha: 0.5)
        addChild(instructionsText)
    }
    
    // MARK: Touch events
    
    var touchPoint: CGPoint = CGPoint()
    var touching: Bool = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first?.location(in: self) {
            if anObject.frame.contains(touch) {
                touchPoint = touch
                touching = true
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let location = t.location(in: self)
            touchPoint = location
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touching = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touching = false
    }
    
    // MARK: Update
    
    override func update(_ currentTime: TimeInterval) {
        
        if touching {
            let _timeInterval: CGFloat = 1.0 / 120.0
            
            let distance = CGVector(
                dx: touchPoint.x - anObject.position.x,
                dy: touchPoint.y - anObject.position.y
            )
            
            let velocity = CGVector(
                dx: distance.dx / _timeInterval * 0.4,
                dy: distance.dy / _timeInterval * 0.4
            )
            
            anObject.physicsBody!.velocity = velocity
        }
    }
}

#Preview {
    FlingDrag()
}
