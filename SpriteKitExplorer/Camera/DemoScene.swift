/**
 
 # A demo scene to try out the custom cameras
 
 Achraf Kassioui
 Created: 8 April 2024
 Updated: 8 April 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - Live preview

struct CameraDemoView: View {
    var myScene = CameraDemoScene()
    
    var body: some View {
        SpriteView(
            scene: myScene,
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

class CameraDemoScene: SKScene, UIGestureRecognizerDelegate {
    
    let cameraBaseScale: (x: CGFloat, y: CGFloat) = (1, 1)
    
    override func didMove(to view: SKView) {
        /// configure view
        size = view.bounds.size
        scaleMode = .resizeFill
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
        
        /// create objects
        let sprite = SKSpriteNode(color: .systemRed, size: CGSize(width: 60, height: 60))
        sprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 60, height: 60))
        sprite.physicsBody?.restitution = 1
        sprite.physicsBody?.linearDamping = 0
        sprite.zPosition = 10
        sprite.position.y = 300
        sprite.zRotation = .pi * 0.25
        addChild(sprite)
        
        if let gridTexture = generateGridTexture(cellSize: 60, rows: 20, cols: 20, color: SKColor(white: 0, alpha: 0.15)) {
            let gridbackground = SKSpriteNode(texture: gridTexture)
            gridbackground.zPosition = -1
            addChild(gridbackground)
        }
        
        let viewFrame = SKShapeNode(rectOf: CGSize(width: view.frame.width, height: view.frame.height))
        viewFrame.lineWidth = 3
        viewFrame.strokeColor = SKColor(white: 0, alpha: 0.9)
        viewFrame.lineJoin = .miter
        addChild(viewFrame)
        
        let yAxis = SKShapeNode(rectOf: CGSize(width: 1, height: 10000))
        yAxis.strokeColor = SKColor(white: 0, alpha: 0.1)
        addChild(yAxis)
        
        let xAxis = SKShapeNode(rectOf: CGSize(width: 10000, height: 1))
        xAxis.isAntialiased = false
        xAxis.strokeColor = SKColor(white: 0, alpha: 0.1)
        addChild(xAxis)
        
        /// create camera
        let myCamera = InertialCamera(view: view, scene: self)
        camera = myCamera
        addChild(myCamera)
        myCamera.xScale = cameraBaseScale.x
        myCamera.yScale = cameraBaseScale.y
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
            iconName: "lock.fill",
            iconSize: CGSize(width: 14, height: 20),
            onTouch: toggleCameraLock
        )
        
        lockCameraButton.position = CGPoint(
            x: 70,
            y: -view.frame.height/2 + view.safeAreaInsets.bottom + buttonSize.height/2 + spacing
        )
        
        camera?.addChild(lockCameraButton)
    }
    
    func toggleCameraLock() {
        if let myCamera = self.camera as? InertialCamera {
            myCamera.lock.toggle()
        }
    }
    
    /// reset camera
    func createResetCameraButton(with view: SKView) {
        let resetCameraButton = ButtonWithIconAndPattern(
            size: buttonSize,
            iconName: "arrow.counterclockwise",
            iconSize: CGSize(width: 20, height: 24),
            onTouch: resetCamera
        )
        
        resetCameraButton.position = CGPoint(
            x: 0,
            y: -view.frame.height/2 + view.safeAreaInsets.bottom + buttonSize.height/2 + spacing
        )
        
        camera?.addChild(resetCameraButton)
    }
    
    func resetCamera(){
        if let inertialCamera = self.camera as? InertialCamera {
            inertialCamera.stopInertia()
            inertialCamera.setCameraTo(
                position: .zero,
                xScale: self.cameraBaseScale.x,
                yScale: self.cameraBaseScale.y,
                rotation: 0
            )
        }
    }
    
    // MARK: Update loop
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.updateInertia()
        }
    }
    
}

