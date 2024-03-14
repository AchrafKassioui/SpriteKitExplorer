/**
 
 # shouldRender callback
 
 When a SpriteKit view is initialized, for example with SwiftUI's SpriteView, one of the available parameters is `shouldRender`, like so:
 ```
 SpriteView(
     scene: MySpriteKitScene(),
     shouldRender: { currentTime in
        // currentTime is of type TimeInterval
        // some logic that returns true or false
        // the default is `true`, i.e. the frame will render
        true
     }
 )
 ```
 The documentation says:
 
 - Parameter shouldRender: callback that allows to dynamically control the render rate.
    Return true to initiate and update for the target time
    Return false to skip update and render for the target time
 
 But I'm not sure how it works and what are the use cases. I find that it slows the rendering.
 
 Created: 5 March 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct ShouldRender: View {
    var myScene = ShouldRenderScene()
    
    @State private var lastRenderTime: TimeInterval = 0
    let targetFrameInterval: TimeInterval = 1.0 / 30.0 // target frame rate
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                preferredFramesPerSecond: 120,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount],
                shouldRender: { currentTime in
                    // Determine if enough time has elapsed since the last frame was rendered
                    if currentTime - lastRenderTime >= targetFrameInterval {
                        lastRenderTime = currentTime
                        return true // Render this frame
                    }
                    return false // Skip this frame
                }
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - SpriteKit

class ShouldRenderScene: SKScene {
    
    var anObject: SKShapeNode!
    
    // MARK: didLoad
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .lightGray
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        createGridOfSprites()
    }
    
    // MARK: didMove
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        setupPhysicsBoundaries()
    }
    
    // MARK: didChangeSize
    override func didChangeSize(_ oldSize: CGSize) {
        setupPhysicsBoundaries()
    }
    
    // MARK: Scene Setup
    func setupPhysicsBoundaries() {
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody = borderBody
    }
    
    // MARK: Create objects
    func createGridOfSprites() {
        let spriteSize = CGSize(width: 15, height: 15)
        let leftViewBound: CGFloat = -160
        let rightViewBound: CGFloat = 160
        let bottomViewBound: CGFloat = -100
        let topViewBound: CGFloat = 200
        
        for i in stride(from: leftViewBound, to: rightViewBound, by: spriteSize.width + 15) {
            for j in stride(from: bottomViewBound, to: topViewBound, by: spriteSize.width + 15) {
                let sprite = SKSpriteNode(color: .white, size: spriteSize)
                sprite.position = CGPoint(x: i, y: j)
                sprite.physicsBody = SKPhysicsBody(rectangleOf: spriteSize)
                addChild(sprite)
            }
        }
    }
}

#Preview {
    ShouldRender()
}


