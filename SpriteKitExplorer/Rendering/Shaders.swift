/**
 
 # SpriteKit Shaders
 
 Achraf Kassioui
 Created: 30 March 2024
 Updated: 30 March 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - Live preview

struct ShadersView: View {
    var myScene = ShadersScene()
    
    var body: some View {
        SpriteView(
            scene: myScene,
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
            debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS, .showsPhysics]
        )
        .background(.black)
    }
}

#Preview {
    ShadersView()
}

// MARK: - Scene setup

class ShadersScene: SKScene {
    
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
    var shaderContainer = SKSpriteNode()
    
    func setupNavigationCamera(with view: SKView) {
        navigationCamera.name = "camera-main"
        navigationCamera.xScale = (view.bounds.size.width / size.width)
        navigationCamera.yScale = (view.bounds.size.height / size.height)
        scene?.camera = navigationCamera
        navigationCamera.setScale(1)
        
        addChild(navigationCamera)
    }
    
    func createSomeObjects(with view: SKView) {
        shaderContainer = SKSpriteNode(color: .gray, size: CGSize(width: 390, height: 844))
        createWaterMovementShader(shaderContainer)
        addChild(shaderContainer)
    }
    
    /// source:
    /// https://github.com/eleev/ios-spritekit-shader-sandbox/blob/master/spritekit-fragment-sandbox-ios-app/Scenes/GameScene.swift#L363
    private func createWaterMovementShader(_ shaderContainer: SKSpriteNode, for imageNamed: String = "cartoon-landscape-1024") {
        let multiplier: CGFloat = 1
        let size = getSceneResolution(multiplier: multiplier)
        
        let moveShader = SKShader(fileNamed: "water-movement.fsh")
        moveShader.uniforms = [
            SKUniform(name: "size", vectorFloat3: size),
            SKUniform(name: "customTexture", texture: SKTexture(imageNamed: imageNamed))
        ]
        shaderContainer.shader = moveShader
    }
    
    private func getSceneResolution(multiplier: CGFloat = 1.0) -> SIMD3<Float> {
        let width = Float(self.frame.size.width * multiplier)
        let height = Float(self.frame.size.height * multiplier)
        let size = SIMD3<Float>([width, height, 0])
        return size
    }
    
    override func update(_ currentTime: TimeInterval) {
        
    }
}
