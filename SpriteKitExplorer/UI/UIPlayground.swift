/**
 
 # UI Playground
 
 Achraf Kassioui
 Created: 23 April 2024
 Updated: 24 April 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - Live preview

struct UIPlaygroundView: View {
    @State private var sceneId = UUID()
    
    var body: some View {
        SpriteView(
            scene: UIPlaygroundScene(),
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
            debugOptions: [.showsFPS, .showsDrawCount, .showsNodeCount]
        )
        /// force recreation using the unique ID
        .id(sceneId)
        .onAppear {
            /// generate a new ID on each appearance
            sceneId = UUID()
        }
        .ignoresSafeArea()
        .background(.black)
    }
}

#Preview {
    UIPlaygroundView()
}


class UIPlaygroundScene: SKScene {
    
    // MARK: - Scene setup
    
    override func didMove(to view: SKView) {
        /// configure view
        size = view.bounds.size
        scaleMode = .resizeFill
        view.contentMode = .center
        backgroundColor = SKColor(white: 1, alpha: 1)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.speed = 1
        let physicsBoundaries = CGRect(
            x: -view.frame.width / 2,
            y: -view.frame.height / 2,
            width: view.frame.width,
            height: view.frame.height
        )
        physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBoundaries)
        
        let viewFrame = SKShapeNode(rect: physicsBoundaries)
        viewFrame.lineWidth = 3
        viewFrame.strokeColor = SKColor(white: 0, alpha: 0.9)
        addChild(viewFrame)
        
        /// create objects
        let sprite = SKSpriteNode(color: .systemRed, size: CGSize(width: 60, height: 60))
        sprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 60, height: 60))
        sprite.zPosition = 10
        sprite.position.y = 300
        sprite.zRotation = .pi * 0.25
        addChild(sprite)
        
        let gridTexture = generateGridTexture(cellSize: 60, rows: 20, cols: 20, linesColor: SKColor(white: 0, alpha: 0.15))
        let gridbackground = SKSpriteNode(texture: gridTexture)
        gridbackground.zPosition = -1
        addChild(gridbackground)
        
        /// create camera
        let myCamera = InertialCamera(scene: self)
        camera = myCamera
        addChild(myCamera)
        myCamera.zPosition = 99999
        
        /// UI
        resetCameraUI()
    }
    
    // MARK: - UI
    
    func resetCameraUI() {
        let resetCameraButton = ButtonWithDotPattern(
            size: CGSize(width: 60, height: 60),
            icon: SKTexture(imageNamed: "viewfinder"),
            onAction: {
                if let inertialCamera = self.camera as? InertialCamera {
                    inertialCamera.stopInertia()
                    inertialCamera.setTo(position: .zero, xScale: 1, yScale: 1, rotation: 0)
                }
            }
        )
        resetCameraButton.physicsBody = SKPhysicsBody(circleOfRadius: 30)
        addChild(resetCameraButton)
    }
    
    // MARK: - Update loop
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.update()
        }
    }
    
    // MARK: - Touch events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.stopInertia()
        }
    }
    
}
