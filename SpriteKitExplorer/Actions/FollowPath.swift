/**
 
 # Follow Path Action
 
 I wanted to see what happens when we change the path of a follow path action.
 If the path of the action is updated, the action is restarted. The node that follows the action does not readjust its trajectory from its current position.
 
 Achraf Kassioui
 Created 15 November 2024
 Updated 18 November 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

/// The main SwiftUI view
struct FollowPathView: View {
    var myScene = FollowPathScene()
    @State private var isPaused: Bool = false
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount, .showsQuadCount, .showsPhysics]
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
    FollowPathView()
}

class FollowPathScene: SKScene {
    
    // MARK: References
    
    var sprite = SKSpriteNode()
    var shapeForPath = SKShapeNode()
    var followAction: SKAction!
    var pointToChange = CGPoint(x: -100, y: 0)
    
    // MARK: Scene Setup
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        let camera = SKCameraNode()
        self.camera = camera
        camera.setScale(1)
        addChild(camera)
        
        createShape()
        createEntity()
        updatePath()
        updateAction()
        
        let label = SKLabelNode(text: "Drag anywhere to update the path for the action.")
        label.fontName = "Menlo-Bold"
        label.fontSize = 20
        label.preferredMaxLayoutWidth = 300
        label.numberOfLines = 0
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 300)
        addChild(label)
    }
    
    func updateAction() {
        guard let path = shapeForPath.path else { return }
        followAction = SKAction.follow(path, asOffset: false, orientToPath: true, speed: 200)
        sprite.run(SKAction.repeatForever(followAction))
    }
    
    func createEntity() {
        sprite = SKSpriteNode(imageNamed: "rectangle-60-20-fill")
        sprite.colorBlendFactor = 1
        sprite.color = .systemYellow
        sprite.position = pointToChange
        addChild(sprite)
    }
    
    func createShape() {
        shapeForPath = SKShapeNode()
        shapeForPath.lineWidth = 10
        shapeForPath.strokeColor = .darkGray
        shapeForPath.lineJoin = .round
        addChild(shapeForPath)
    }
    
    func updatePath() {
        var pathPoints: [CGPoint] = [
            pointToChange,
            CGPoint(x: 0, y: 100),
            CGPoint(x: 100, y: 0),
            CGPoint(x: 0, y: -100),
            pointToChange
        ]
        
        let shape = SKShapeNode(splinePoints: &pathPoints, count: pathPoints.count)
        
        shapeForPath.path = shape.path
    }
    
    // MARK: Touch
    
    var touchOffset = CGPoint.zero
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            touchOffset = touchLocation - pointToChange
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            pointToChange = touchLocation - touchOffset
            sprite.position = touchLocation - touchOffset
            updatePath()
            updateAction()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchOffset = .zero
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
