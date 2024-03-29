/**
 
 # Touch events
 
 Exploring touch handling in SpriteKit
 
 Created: 19 March 2024
 
 */

import SwiftUI
import SpriteKit

struct TouchEventsView: View {
    var myScene = TouchEventsScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS, .showsPhysics]
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    TouchEventsView()
}

class TouchEventsScene: SKScene {
    
    // MARK: - Scene setup
    
    override func didMove(to view: SKView) {
        name = "scene"
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .gray
        setupCamera()
        drawGrid()
    }
    
    func setupCamera() {
        let camera = SKCameraNode()
        camera.name = "camera"
        let viewSize = view?.bounds.size
        camera.xScale = (viewSize!.width / size.width)
        camera.yScale = (viewSize!.height / size.height)
        addChild(camera)
        scene?.camera = camera
        camera.setScale(1)
    }
    
    /**
     
     # Create a grid an animate its creation
     
     Not relevant to touch events. This is a cosmetic experiment.
     
     */
    func drawGrid() {
        let scaleDuration: TimeInterval = 0.5
        let moveDuration: TimeInterval = 0 // Use the same duration for simultaneous scaling and moving
        
        // Starting size for both line types to ensure they grow from a point.
        let startingSize = CGSize(width: 1, height: 1)
        let color = SKColor(white: 1, alpha: 0.3)
        
        for i in -8..<8 {
            let finalXPosition = CGFloat(i * 60)
            
            let vLine = SKSpriteNode(color: color, size: startingSize)
            vLine.position = CGPoint(x: 0, y: 0) // Start from the center
            vLine.zPosition = -1
            addChild(vLine)
            
            // Scale and move actions
            let scaleYAction = SKAction.scaleY(to: 844, duration: scaleDuration)
            let moveXAction = SKAction.moveTo(x: finalXPosition, duration: moveDuration)
            
            vLine.run(SKAction.group([scaleYAction, moveXAction])) // Run simultaneously
        }
        
        for i in -8..<8 {
            let finalYPosition = CGFloat(i * 60)
            
            let hLine = SKSpriteNode(color: color, size: startingSize)
            hLine.position = CGPoint(x: 0, y: 0) // Start from the center
            hLine.zPosition = -1
            addChild(hLine)
            
            // Scale and move actions
            let scaleXAction = SKAction.scaleX(to: 844, duration: scaleDuration)
            let moveYAction = SKAction.moveTo(y: finalYPosition, duration: moveDuration)
            
            hLine.run(SKAction.group([scaleXAction, moveYAction])) // Run simultaneously
        }
    }
    
    // MARK: - Touch visualization
    /**
     
     For each touch point on screen:
     - visualize the touch area
     - display the touch point coordinates
     
     */
    var touchLabels = [UITouch: SKLabelNode]()
    var touchPoints = [UITouch: SKShapeNode]()
    
    func visualizeTouchesBegan(_ touch: UITouch) {
        let touchLocation = touch.location(in: self)
        
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.fontSize = 32
        label.zPosition = 1
        label.text = pointToString(touchLocation)
        label.position = CGPoint(x: touchLocation.x, y: touchLocation.y + 60)
        addChild(label)
        touchLabels[touch] = label
        
        let touchPoint = SKShapeNode(circleOfRadius: touch.majorRadius)
        touchPoint.name = "touch-point"
        touchPoint.lineWidth = 0
        touchPoint.fillColor = .systemRed
        touchPoint.position = CGPoint(x: touchLocation.x, y: touchLocation.y)
        addChild(touchPoint)
        touchPoints[touch] = touchPoint
    }
    
    func visualizeTouchesMoved(_ touch: UITouch) {
        guard let label = touchLabels[touch],
              let touchPoint = touchPoints[touch] else { return }
        
        let touchLocation = touch.location(in: self)
        
        label.position = CGPoint(x: touchLocation.x, y: touchLocation.y + 60)
        label.text = pointToString(touchLocation)
        
        let newPath = CGPath(ellipseIn: CGRect(x: -touch.majorRadius, y: -touch.majorRadius, width: touch.majorRadius * 2, height: touch.majorRadius * 2), transform: nil)
        touchPoint.path = newPath
        touchPoint.position = CGPoint(x: touchLocation.x, y: touchLocation.y)
    }
    
    func visualizeTouchesEnded(_ touches: Set<UITouch>) {
        for touch in touches {
            touchLabels[touch]?.removeFromParent()
            touchLabels[touch] = nil
            
            touchPoints[touch]?.removeFromParent()
            touchLabels[touch] = nil
        }
    }
    
    // MARK: - Touch events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            visualizeTouchesBegan(touch)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            visualizeTouchesMoved(touch)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        visualizeTouchesEnded(touches)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

}
