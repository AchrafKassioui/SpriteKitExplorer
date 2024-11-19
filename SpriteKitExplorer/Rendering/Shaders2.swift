/**
 
 # SpriteKit Shaders
 
 Achraf Kassioui
 Created: 30 March 2024
 Updated: 30 March 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - Live preview

struct Shaders2View: View {
    var myScene = Shaders2Scene()
    
    var body: some View {
        SpriteView(
            scene: myScene,
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
            debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS]
        )
        .background(.black)
    }
}

#Preview {
    Shaders2View()
}

// MARK: - Scene setup

class Shaders2Scene: SKScene {
    
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .black
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        let physicsBoundaries = CGRect(
            x: -view.frame.width / 2,
            y: -view.frame.height / 2,
            width: view.frame.width,
            height: view.frame.height
        )
        physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBoundaries)
        
        setupNavigationCamera(with: view)
        createSomeObjects(with: view)
    }
    
    // MARK: - Create objects
    
    let navigationCamera = SKCameraNode()
    let motionBlurShader = SKShader(fileNamed: "motion-blur")
    
    func setupNavigationCamera(with view: SKView) {
        navigationCamera.name = "camera-main"
        navigationCamera.xScale = (view.bounds.size.width / size.width)
        navigationCamera.yScale = (view.bounds.size.height / size.height)
        scene?.camera = navigationCamera
        navigationCamera.setScale(1)
        
        addChild(navigationCamera)
    }
    
    func createSomeObjects(with view: SKView) {
        let square = SKSpriteNode(color: SKColor.red, size: CGSize(width: 60, height: 60))
        square.texture = SKTexture(imageNamed: "basketball-94")
        square.zPosition = 1
        square.position.y = 100
        square.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 60, height: 60))
        square.physicsBody?.restitution = 1
        square.shader = motionBlurShader
        
        addChild(square)
        
        let colorWheel = SKSpriteNode(imageNamed: "color-wheel-2")
        colorWheel.zPosition = 2
        colorWheel.physicsBody = SKPhysicsBody(circleOfRadius: 90)
        colorWheel.physicsBody?.restitution = 1
        colorWheel.position.y = -100
        colorWheel.shader = motionBlurShader
        
        addChild(colorWheel)
    }
    
    override func update(_ currentTime: TimeInterval) {
        
    }
}
