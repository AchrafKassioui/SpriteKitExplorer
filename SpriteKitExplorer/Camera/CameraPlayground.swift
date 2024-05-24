/**
 
 # Camera Playground
 
 A file to try out cameras in SpriteKit
 
 Achraf Kassioui
 Created: 8 April 2024
 Updated: 23 April 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - Live preview

struct CameraDemoView: View {
    
    var body: some View {
        SpriteView(
            scene: CameraDemoScene(),
            preferredFramesPerSecond: 120,
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
            debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS]
        )
        .ignoresSafeArea()
    }
}

#Preview {
    CameraDemoView()
}

// MARK: - Demo scene

class CameraDemoScene: SKScene {
    
    override func didMove(to view: SKView) {
        /// configure view
        size = view.bounds.size
        scaleMode = .resizeFill
        view.contentMode = .center
        backgroundColor = SKColor(red: 0.89, green: 0.89, blue: 0.84, alpha: 1)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.speed = 0
        let physicsBoundaries = CGRect(
            x: -view.frame.width / 2,
            y: -view.frame.height / 2,
            width: view.frame.width,
            height: view.frame.height
        )
        physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBoundaries)
        physicsBody?.restitution = 1
        
        let viewFrame = SKShapeNode(rect: physicsBoundaries)
        viewFrame.lineWidth = 3
        viewFrame.strokeColor = SKColor(white: 0, alpha: 0.9)
        addChild(viewFrame)
        
        /// create objects
        let sprite = SKSpriteNode(color: .systemRed, size: CGSize(width: 60, height: 60))
        sprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 60, height: 60))
        sprite.physicsBody?.restitution = 1
        sprite.physicsBody?.linearDamping = 0
        sprite.zPosition = 10
        sprite.position.y = 300
        sprite.zRotation = .pi * 0.25
        addChild(sprite)
        
        let gridTexture = generateGridTexture(cellSize: 60, rows: 20, cols: 20, linesColor: SKColor(white: 0, alpha: 0.15))
        let gridbackground = SKSpriteNode(texture: gridTexture)
        gridbackground.zPosition = -1
        addChild(gridbackground)
        
        let yAxis = SKShapeNode(rectOf: CGSize(width: 1, height: 10000))
        yAxis.strokeColor = SKColor(white: 0, alpha: 0.1)
        addChild(yAxis)
        
        let xAxis = SKShapeNode(rectOf: CGSize(width: 10000, height: 1))
        xAxis.isAntialiased = false
        xAxis.strokeColor = SKColor(white: 0, alpha: 0.1)
        addChild(xAxis)
        
        /// create camera
        let myCamera = InertialCamera(scene: self)
        camera = myCamera
        addChild(myCamera)
        myCamera.zPosition = 99999
        
        /// create visualization
        let gestureVisualizationHelper = GestureVisualizationHelper(view: view, scene: self)
        addChild(gestureVisualizationHelper)
        
        /// create UI
        createResetCameraButton(with: view)
        createCameraLockButton(with: view)
    }
    
    // MARK: UI
    
    let spacing: CGFloat = 20
    let buttonSize = CGSize(width: 60, height: 60)
    
    /// lock camera
    func createCameraLockButton(with view: SKView) {
        let lockCameraButton = ButtonWithIconAndPattern(
            size: buttonSize,
            icon1: "lock-open",
            icon2: "lock",
            iconSize: CGSize(width: 32, height: 32),
            onTouch: {
                if let myCamera = self.camera as? InertialCamera {
                    myCamera.stopInertia()
                    myCamera.lock.toggle()
                }
            }
        )
        
        lockCameraButton.position = CGPoint(
            x: -view.frame.width/2 + view.safeAreaInsets.left + buttonSize.width/2 + spacing,
            y: -view.frame.height/2 + view.safeAreaInsets.bottom + buttonSize.height/2 + spacing
        )
        
        camera?.addChild(lockCameraButton)
    }
    
    /// reset camera
    func createResetCameraButton(with view: SKView) {
        let resetCameraButton = ButtonWithIconAndPattern(
            size: buttonSize,
            icon1: "arrow-counterclockwise",
            icon2: "arrow-counterclockwise",
            iconSize: CGSize(width: 32, height: 32),
            onTouch: {
                if let inertialCamera = self.camera as? InertialCamera {
                    inertialCamera.stopInertia()
                    inertialCamera.setTo(
                        position: .zero,
                        xScale: 1,
                        yScale: 1,
                        rotation: 0
                    )
                }
            }
        )
        
        resetCameraButton.position = CGPoint(
            x: 0,
            y: -view.frame.height/2 + view.safeAreaInsets.bottom + buttonSize.height/2 + spacing
        )
        
        camera?.addChild(resetCameraButton)
    }
    
    // MARK: Update loop
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.updateInertia()
        }
    }
    
    // MARK: Touch events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.stopInertia()
        }
    }
    
}



