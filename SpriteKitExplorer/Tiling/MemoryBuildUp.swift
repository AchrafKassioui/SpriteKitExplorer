/**
 
 # SpriteKit Memory Buildup
 
 Testing memory build up of a SpriteKit scene when it is presented again and again.
 
 ## Reference to `self` in closures
 
 Careful of using `self` inside a closure. Doing so can retain a reference to the instance using it even if the instance isn't used anymore.
 Example:
 ```
 run(SKAction.wait(forDuration: Double(i) * 0.01)) { [weak self] in
    self?.addChild(sprite)
 }
 ```
 The action uses a self. In order to avoid a strong reference, use `[weak self] in`
 
 ## Looping over touches
 
 Using a for loop to handle all touches in a multitouch scenario seems to introduce some memory build up. Handling only one touch doesn't seem so.
 How to handle multiple touches without introducing strong references and retain cycles?
 
 
 Achraf Kassioui
 Created 23 November 2024
 Updated 24 November 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

struct MemoryBuildUpView: View {
    @State private var sceneID = UUID()
    var body: some View {
        SpriteView(
            scene: MemoryBuildUpScene(),
            debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount, .showsQuadCount, .showsPhysics]
        )
        .id(sceneID)
        .onAppear { sceneID = UUID() }
        .ignoresSafeArea()
        .background(Color(SKColor.black))
        .persistentSystemOverlays(.hidden)
    }
}

#Preview {
    MemoryBuildUpView()
}

class MemoryBuildUpScene: SKScene {
    
    // MARK: Scene Setup
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        
        createSomeNodes()
        createButton()
    }
    
    // MARK: Create Something
    
    func createSomeNodes() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -10)
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        for i in 1...300 {
            let sprite = SKSpriteNode(color: .systemYellow, size: CGSize(width: 10, height: 10))
            sprite.name = "NaNCandidate"
            sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
            sprite.physicsBody?.charge = -0.5
            
            run(SKAction.wait(forDuration: Double(i) * 0.01)) { [weak self] in
                self?.addChild(sprite)
            }
        }
        
        let field = SKFieldNode.electricField()
        field.position = CGPoint(x: -1, y: -1)
        field.minimumRadius = 100
        field.strength = 1
        addChild(field)
    }
    
    // MARK: Update
    
    override func update(_ currentTime: TimeInterval) {
        /// In some extreme cases, a physics simulation would make a node disappear from the scene. Even constraints wouldn't hold it in.
        /// Logging the disappearing node position returns a NaN value.
        /// This enumeration checks if the position is NaN, and brings back the node into view.
        enumerateChildNodes(withName: "//*NaNCandidate*", using: { node, stop in
            if node.position.x.isNaN || node.position.y.isNaN {
                print("position is absurd")
                node.physicsBody?.velocity = .zero
                node.physicsBody?.angularVelocity = 0
                node.position = CGPoint(x: 100, y: 100)
            }
        })
    }
    
    // MARK: Present Scene
    
    func presentSceneAgain() {
        guard let view = self.view else { return }
        print("presentSceneAgain MemoryBuildUpScene")
        view.presentScene(MemoryBuildUpScene())
    }
    
    // MARK: Buttons
    
    func createButton() {
        let shape = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 12)
        shape.name = "button"
        shape.lineWidth = 2
        shape.strokeColor = SKColor(white: 0, alpha: 0.6)
        shape.fillColor = SKColor(white: 0, alpha: 0.3)
        shape.position = CGPoint(x: 0, y: -330)
        addChild(shape)
        
        let label = SKLabelNode(text: "Present Scene")
        label.fontName = "Menlo-Bold"
        label.fontSize = 18
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        shape.addChild(label)
    }
    
    // MARK: Touch
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        print("\ntouchesBegan MemoryBuildUpScene")
        
        let touchedNodes = nodes(at: touch.location(in: self))
        if let topNode = touchedNodes.max(by: { $0.zPosition > $1.zPosition}) {
            if topNode.name == "button" || topNode.inParentHierarchy(childNode(withName: "button")!) {
                presentSceneAgain()
            }
        }
    }
}
