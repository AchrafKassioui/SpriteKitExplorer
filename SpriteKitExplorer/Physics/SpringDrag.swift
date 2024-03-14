/**
 
 # Spring Drag
 
 A setup to explore how to drag a SpriteKit node on screen, but using physics, such as a spring drag.
 An example of such drag can be found here: http://davidbau.com/archives/2010/11/26/box2d_web.html
 
 Work in progress...

 Created: 25 January 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct SpringDrag: View {
    var myScene = SpringDragScene()
    
    var body: some View {
        ZStack {
            VStack (spacing: 0) {
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

class SpringDragScene: SKScene, UIGestureRecognizerDelegate {
    
    var canvasSize: CGSize = CGSize(width: 300, height: 700)
    var aSprite: SKSpriteNode!
    var touchHook: SKShapeNode!
    var springJoint: SKPhysicsJointSpring!
    
    // MARK: Setup scene
    
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .lightGray
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        createObjects()
    }
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        setupPhysicsBoundaries()
        
        /*
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(gesture:)))
        view.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = self
         */
    }
    
    func setupPhysicsBoundaries() {
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        borderBody.friction = 0
        borderBody.restitution = 0.5
        self.physicsBody = borderBody
    }
    
    // MARK: Create objects
    
    func createObjects() {
        let canvasFrame = SKShapeNode(rectOf: canvasSize)
        addChild(canvasFrame)
        
        aSprite = SKSpriteNode(color: .systemYellow, size: CGSize(width: 60, height: 60))
        aSprite.name = "draggable"
        aSprite.zPosition = 10
        aSprite.position = CGPoint(x: 0, y: 0)
        aSprite.physicsBody = SKPhysicsBody(rectangleOf: aSprite.size)
        aSprite.physicsBody?.linearDamping = 1
        addChild(aSprite)
    }
    
    // MARK: Pan gesture
    
    @objc private func handlePanGesture(gesture: UIPanGestureRecognizer) {
        
        //let translation = gesture.translation(in: view)
        
        switch gesture.state {
        case .began:
            print("Begin panning")
            
        case .changed:
            print(gesture.velocity(in: view))
            
        case .ended:
            print("End panning")
            
            /// Check if the translation has moved significantly. For example, more than 2 points.
                
                // get gesture velocity. Convert UIKit coordinates to SpriteKit coordinates
                // remove previous inertia
                // apply inertia
        default:
            break
        }
    }
    
    // MARK: Dragging objects
    
    var selectedNodes: [UITouch: SKNode] = [:]
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = self.atPoint(location)
            if (touchedNode.name == "draggable") {
                selectedNodes[touch] = touchedNode
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if let selectedNode = selectedNodes[touch] {
                selectedNode.position = location
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            selectedNodes.removeValue(forKey: touch)
        }
    }
    
}

#Preview {
    SpringDrag()
}
