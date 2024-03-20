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
                debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS]
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    TouchEventsView()
}

class TouchEventsScene: SKScene {
    
    var label = SKLabelNode()
    
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .gray
        setupCamera()
        setupLabel()
        drawGrid()
    }
    
    func setupCamera() {
        let camera = SKCameraNode()
        let viewSize = view?.bounds.size
        camera.xScale = (viewSize!.width / size.width)
        camera.yScale = (viewSize!.height / size.height)
        addChild(camera)
        scene?.camera = camera
        camera.setScale(1)
    }
    
    func setupLabel() {
        label.text = "..."
        label.fontName = "Menlo-Bold"
        label.fontSize = 32
        label.zPosition = 1
        addChild(label)
    }
    
    func drawGrid() {
        let scaleDuration: TimeInterval = 1
        let moveDuration: TimeInterval = 0 // Use the same duration for simultaneous scaling and moving
        
        // Starting size for both line types to ensure they grow from a point.
        let startingSize = CGSize(width: 1, height: 1)
        let color = SKColor(white: 1, alpha: 0.2)
        
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


    
    // MARK: Touch functions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.first != nil else { return }
        
        for touch in touches {
            //let touchLocation = touch.location(in: scene!)
            //label.text = pointToString(touchLocation)
            
            let d6 = GKRandomDistribution.d6()
            let choice = d6.nextInt()
            label.text = String(describing: choice)
        }
    }
}

import GameplayKit
