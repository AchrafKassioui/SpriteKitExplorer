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
        .ignoresSafeArea()
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
        backgroundColor = SKColor(red: 0.13, green: 0.43, blue: 0.32, alpha: 1)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        let physicsBoundaries = CGRect(
            x: -view.frame.width / 2,
            y: -view.frame.height / 2,
            width: view.frame.width,
            height: view.frame.height
        )
        physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBoundaries)
        
        let inertialCamera = InertialCamera(scene: self)
        camera = inertialCamera
        addChild(inertialCamera)
        
        gradientBall()
        //createSomeObjects(with: view)
    }
    
    // MARK: - Gradient shader
    
    func gradientBall() {
        let ballRadius = 100.0
        let ball = SKShapeNode(circleOfRadius: ballRadius)
        
        let shader = SKShader(source: """
        void main() {
            float dist = distance(v_tex_coord, vec2(0.4, 0.6)); // Adjust center to 40%, 40%
            vec3 colorCream = vec3(0.957, 0.941, 0.733);
            vec3 colorCoffee = vec3(0.482, 0.294, 0.224);
            vec3 colorBrown = vec3(0.263, 0.161, 0.122);
            vec3 mixedColor1 = mix(colorCream, colorCoffee, 0.1);  // 90% cream, 10% coffee
            vec3 mixedColor2 = mix(colorCream, colorCoffee, 0.6);  // 40% cream, 60% coffee
            vec3 mixedColor3 = mix(colorCream, colorBrown, 0.9);  // 10% cream, 90% brown
            vec3 color = mix(mixedColor1, mixedColor2, smoothstep(0.05, 0.5, dist));
            color = mix(color, mixedColor3, smoothstep(0.5, 0.8, dist));
            gl_FragColor = vec4(color, 1.0);
        }
        """)
        
        ball.fillShader = shader
        ball.strokeColor = SKColor.clear
        
        let shadowNode = SKShapeNode(circleOfRadius: ballRadius + 5)
        shadowNode.fillColor = UIColor.black.withAlphaComponent(0.15)
        shadowNode.strokeColor = SKColor.clear
        shadowNode.position = CGPoint(x: 10, y: -10)
        
        let shadowBlurNode = SKEffectNode()
        shadowBlurNode.zPosition = -1
        shadowBlurNode.shouldRasterize = true
        shadowBlurNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 35])
        shadowBlurNode.addChild(shadowNode)
        
        ball.addChild(shadowBlurNode)
        
        addChild(ball)
    }
    
    // MARK: - Water shader
    
    var shaderContainer = SKSpriteNode()
    
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
