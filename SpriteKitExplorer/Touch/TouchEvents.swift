/**
 
 # Touch events
 
 Exploring touch handling in SpriteKit.
 
 Created: 19 March 2024
 Updated: 15 October 2024
 
 */

import SwiftUI
import SpriteKit

struct TouchEventsView: View {
    var myScene = TouchEventsScene()
    @State private var isCameraLocked = true
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS]
            )
            .ignoresSafeArea()
            VStack {
                Spacer()
                HStack {
                    Button("Draw grid") {
                        myScene.drawGrid()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(isCameraLocked ? "Unlock Camera" : "Lock Camera") {
                        if let inertialCamera = myScene.camera as? InertialCamera {
                            isCameraLocked.toggle()
                            inertialCamera.lock = isCameraLocked
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

#Preview {
    TouchEventsView()
}

class TouchEventsScene: SKScene {
    
    // MARK: Scene setup
    
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .gray
        setupCamera()
    }
    
    func setupCamera() {
        if camera is InertialCamera { return }
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.lock = true
        camera = inertialCamera
        addChild(inertialCamera)
    }
    
    /**
     
     # Create a grid and animate its creation
     
     Not relevant to touch events. This is a cosmetic experiment.
     
     */
    func drawGrid() {
        guard let view = view else { return }
        
        let scaleDuration: TimeInterval = 1
        let moveDuration: TimeInterval = 0 /// Use the same duration for simultaneous scaling and moving
        
        /// Starting size for both line types to ensure they grow from a point.
        let startingSize = CGSize(width: 1, height: 1)
        let color = SKColor(white: 1, alpha: 0.3)
        
        enumerateChildNodes(withName: "//vLine") { node, _ in
            node.removeFromParent()
        }
        
        enumerateChildNodes(withName: "//hLine") { node, _ in
            node.removeFromParent()
        }
        
        for i in -8..<8 {
            let finalXPosition = CGFloat(i * 60)
            
            let vLine = SKSpriteNode(color: color, size: startingSize)
            vLine.name = "vLine"
            vLine.position = CGPoint(x: 0, y: 0) /// Start from the center
            vLine.zPosition = -1
            addChild(vLine)
            
            /// Scale and move actions
            let scaleYAction = SKAction.scaleY(to: view.bounds.height, duration: scaleDuration)
            scaleYAction.timingMode = .easeOut
            let moveXAction = SKAction.moveTo(x: finalXPosition, duration: moveDuration)
            
            vLine.run(SKAction.group([scaleYAction, moveXAction])) /// Run simultaneously
        }
        
        for i in -8..<8 {
            let finalYPosition = CGFloat(i * 60)
            
            let hLine = SKSpriteNode(color: color, size: startingSize)
            hLine.name = "hLine"
            hLine.position = CGPoint(x: 0, y: 0) /// Start from the center
            hLine.zPosition = -1
            addChild(hLine)
            
            /// Scale and move actions
            let scaleXAction = SKAction.scaleX(to: view.bounds.width, duration: scaleDuration)
            scaleXAction.timingMode = .easeOut
            let moveYAction = SKAction.moveTo(y: finalYPosition, duration: moveDuration)
            
            hLine.run(SKAction.group([scaleXAction, moveYAction])) /// Run simultaneously
        }
    }
    
    // MARK: Touch visualization
    /**
     
     For each touch point on screen:
     - Visualize the touch area. The radius of the visualized area depends on the size of the touch that was reported by the hardware via `majorRadius`.
     - Display the touch coordinates.
     
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
    
    // MARK: Update Loop
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.updateInertia()
        }
    }
    
    // MARK: Touch events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            visualizeTouchesBegan(touch)
            if let inertialCamera = camera as? InertialCamera {
                inertialCamera.stopInertia()
            }
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
