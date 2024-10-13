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
 The documentation says: `shouldRender`: callback that allows to dynamically control the render rate. Return true to initiate and update for the target time Return false to skip update and render for the target time
 
 ## Comment
 
 - If the goal is to set a specific frame rate for the SpriteKit scene, I find using `preferredFramesPerSecond` more reliable than using custom logic inside the `shouldRender` callback. For example, setting a target FPS of 12 inside `shouldRender` results in a framerate of 8 FPS according to the debug view.
 - Running multiple times the same physics simulation shows how undeterministic it is.
 
 Created: 5 March 2024
 
 */

import SwiftUI
import SpriteKit
import UIKit

// MARK: - SwiftUI

struct ShouldRender: View {
    var myScene = ShouldRenderScene()
    
    @State private var lastRenderTime: TimeInterval = 0
    @State private var currentFrameRate: Double = 60
    let targetFrameRate: Double = 20
    
    var body: some View {
        //let targetFrameInterval: TimeInterval = 1.0 / targetFrameRate
        
        ZStack {
            SpriteView(
                scene: myScene,
                //preferredFramesPerSecond: Int(targetFrameRate),
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsFPS, .showsDrawCount]
//                shouldRender: { currentTime in
//                    /// Determine if enough time has elapsed since the last frame was rendered
//                    if currentTime - lastRenderTime >= targetFrameInterval {
//                        lastRenderTime = currentTime
//                        /// Render this frame
//                        return true
//                    } else {
//                        /// Or skip this frame
//                        return false
//                    }
//                }
            )
            .ignoresSafeArea()
            VStack {
                HStack {
                    Button("Reset") {
                        myScene.createGridOfSprites()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Slider(
                        value: $currentFrameRate,
                        in: 10...120,
                        step: 10
                    )
                    .onChange(of: currentFrameRate) {
                        myScene.changeFrameRate(to: Int(currentFrameRate))
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview {
    ShouldRender()
}

// MARK: - SpriteKit

class ShouldRenderScene: SKScene {
    
    // MARK: didMove
    override func didMove(to view: SKView) {
        size = view.bounds.size
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        view.isMultipleTouchEnabled = true
        scaleMode = .resizeFill
        backgroundColor = .lightGray
        physicsWorld.gravity = CGVector(dx: 0, dy: -20)
        setupPhysicsBoundaries()
        runAroundTrack()
        
        let circle = SKShapeNode(circleOfRadius: 3)
        circle.fillColor = .systemYellow
        circle.lineWidth = 0
        circle.zPosition = 1
        addChild(circle)
    }
    
    // MARK: Frame rate
    func changeFrameRate(to frameRate: Int) {
        guard let view = self.view else {
            print("Not SKView found")
            return
        }
        
        view.preferredFramesPerSecond = frameRate
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
    
    // MARK: Create action
    func runAroundTrack() {
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: -115, y: 13))
        bezierPath.addCurve(to: CGPoint(x: -82, y: 91), controlPoint1: CGPoint(x: -154, y: 35), controlPoint2: CGPoint(x: -115, y: 64))
        bezierPath.addCurve(to: CGPoint(x: 2, y: 70), controlPoint1: CGPoint(x: -50, y: 118), controlPoint2: CGPoint(x: -37, y: 67))
        bezierPath.addCurve(to: CGPoint(x: 124, y: 91), controlPoint1: CGPoint(x: 40, y: 74), controlPoint2: CGPoint(x: 105, y: 121))
        bezierPath.addCurve(to: CGPoint(x: 40, y: -82), controlPoint1: CGPoint(x: 144, y: 61), controlPoint2: CGPoint(x: 92, y: -59))
        bezierPath.addCurve(to: CGPoint(x: -115, y: 13), controlPoint1: CGPoint(x: -11, y: -105), controlPoint2: CGPoint(x: -76, y: -10))
        
        let shape = SKShapeNode(path: bezierPath.cgPath)
        shape.name = "shape"
        shape.lineWidth = 30
        shape.strokeColor = .darkGray
        shape.position = .zero
        addChild(shape)
        
        let sprite = SKSpriteNode(color: .systemYellow, size: CGSize(width: 20, height: 60))
        let action = SKAction.follow(bezierPath.cgPath, asOffset: false, orientToPath: true, speed: 500)
        sprite.run(SKAction.repeatForever(action))
        addChild(sprite)
    }
    
    // MARK: Create physics objects
    func createGridOfSprites() {
        guard let view = self.view else { return }
        
        self.enumerateChildNodes(withName: "//*sprite*", using: { node, _ in
            node.removeFromParent()
        })
        
        let spriteSize = CGSize(width: 6, height: 60)
        let leftViewBound: CGFloat = -view.bounds.width/2
        let rightViewBound: CGFloat = view.bounds.width/2
        let topViewBound: CGFloat = view.bounds.height/3
        let bottomViewBound: CGFloat = -view.bounds.height/8
        print(topViewBound)
        
        for i in stride(from: leftViewBound, to: rightViewBound, by: spriteSize.width + 15) {
            for j in stride(from: bottomViewBound, to: topViewBound, by: spriteSize.width + 15) {
                let sprite = SKSpriteNode(color: .darkGray, size: spriteSize)
                sprite.name = "sprite"
                sprite.position = CGPoint(x: i, y: j)
                sprite.physicsBody = SKPhysicsBody(rectangleOf: spriteSize)
                addChild(sprite)
            }
        }
    }
}


