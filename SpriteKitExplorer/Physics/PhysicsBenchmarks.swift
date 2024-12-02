/**
 
 # SpriteKit Physics Benchmarks
 
 Achraf Kassioui
 Created: 19 April 2024
 Updated: 19 April 2024
 
 */

import SwiftUI
import SpriteKit
import CoreImage.CIFilterBuiltins

// MARK: - Live preview

struct PhysicsBenchmarksView: View {
    @State private var sceneId = UUID()
    
    var body: some View {
        SpriteView(
            scene: PhysicsBenchmarksScene(),
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
            debugOptions: [.showsFPS, .showsDrawCount, .showsNodeCount]
        )
        /// force recreation using the unique ID
        .id(sceneId)
        .onAppear {
            /// generate a new ID on each appearance
            sceneId = UUID()
        }
        //.ignoresSafeArea()
    }
}

#Preview {
    PhysicsBenchmarksView()
}

// MARK: - SpriteKit

class PhysicsBenchmarksScene: SKScene {
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        backgroundColor = SKColor(white: 1, alpha: 1)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.speed = 1
        
        let viewFrameRect = CGRect(
            x: -view.frame.width / 2,
            y: -view.frame.height / 2,
            width: view.frame.width,
            height: view.frame.height
        )
        let viewFrame = SKShapeNode(rectOf: viewFrameRect.size)
        viewFrame.lineWidth = 3
        viewFrame.strokeColor = SKColor(white: 0, alpha: 0.9)
        viewFrame.physicsBody = SKPhysicsBody(edgeLoopFrom: viewFrameRect)
        addChild(viewFrame)
        
        let ground = SKSpriteNode(color: .gray, size: CGSize(width: 300, height: 4))
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        //addChild(ground)
        
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.zPosition = 999
        camera = inertialCamera
        addChild(inertialCamera)
        
        let backgroundTexture = generateGridTexture(cellSize: 60, rows: 30, cols: 30, linesColor: SKColor(white: 0, alpha: 0.3))
        let background = SKSpriteNode(texture: backgroundTexture)
        background.zPosition = -1
        addChild(background)
        
        createButton()
    }
    
    // MARK: - UI
    
    func createButton() {
        let buttonLabel = SKLabelNode(text: "Spawn")
        buttonLabel.zPosition = 100
        buttonLabel.name = "button-spawn"
        buttonLabel.fontName = "DINAlternate-Bold"
        buttonLabel.fontSize = 32
        buttonLabel.fontColor = SKColor(white: 0, alpha: 1)
        buttonLabel.position = CGPoint(x: 0, y: 340)
        addChild(buttonLabel)
    }
    
    // MARK: - Physics objects
    
    func velocityBall() -> SKNode {
        let ball = SKSpriteNode(imageNamed: "block_circle")
        ball.name = "velocity-ball"
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 18)
        ball.setScale(0.4)
        
        let velocityShader = SKShader(source: """
        void main() {
            vec3 colorBlue = vec3(0.0, 0.0, 1.0);
            vec3 colorRed = vec3(1.0, 0.0, 0.0);
            vec3 color = mix(colorBlue, colorRed, a_velocity);
        
            float alpha = texture2D(u_texture, v_tex_coord).a; // Get texture alpha
            gl_FragColor = vec4(color * alpha, alpha); // Modify color and maintain alpha
        }
        """)
        velocityShader.attributes = [SKAttribute(name: "a_velocity", type: .float)]
        ball.setValue(SKAttributeValue(float: 0), forAttribute: "a_velocity")
        ball.shader = velocityShader
        
        return ball
    }
    
    func gradientBall() -> SKNode {
        let ballRadius = 10.0
        let ball = SKShapeNode(circleOfRadius: ballRadius)
        ball.strokeColor = SKColor.clear
        ball.name = "gradient-ball"
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ballRadius)
        
        let gradientShader = SKShader(source: """
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

        ball.fillShader = gradientShader
        
        return ball
    }
    
    func square() -> SKNode {
        let square = SKSpriteNode(color: .systemRed, size: CGSize(width: 10, height: 10))
        square.name = "square"
        square.physicsBody = SKPhysicsBody(rectangleOf: square.size)
        
        return square
    }
    
    func circle() -> SKNode {
        let circle = SKSpriteNode(imageNamed: "block_circle")
        circle.name = "circle"
        circle.colorBlendFactor = 1
        circle.color = .systemBlue
        circle.physicsBody = SKPhysicsBody(circleOfRadius: 4.5)
        circle.setScale(0.1)
        
        return circle
    }
    
    func concaveObject() -> SKNode {
        let archTexture = SKTexture(imageNamed: "block_arch")
        let archSize = CGSize(width: 38, height: 18)
        let arch = SKSpriteNode(texture: archTexture, size: archSize)
        arch.name = "arch"
        arch.colorBlendFactor = 1
        arch.color = .systemYellow
        arch.physicsBody = SKPhysicsBody(texture: archTexture, size: archSize)
        
        return arch
    }
    
    func triangleNode() -> SKNode {
        let triangleTexture = SKTexture(imageNamed: "block_triangle")
        let triangleSize = CGSize(width: 36, height: 18)
        let physicalSize = CGSize(width: 34, height: 17)
        let triangle = SKSpriteNode(texture: triangleTexture, size: triangleSize)
        triangle.name = "triangle"
        triangle.colorBlendFactor = 1
        triangle.color = .systemYellow
        triangle.physicsBody = SKPhysicsBody(texture: triangleTexture, size: physicalSize)
        
        return triangle
    }
    
    // MARK: - Spawn objects
    
    func spawnNodes(nodeToSpawn: SKNode, spawnPosition: CGPoint, interval: TimeInterval, count: Int, parent: SKNode) {
        guard let nodeName = nodeToSpawn.name else {
            print("spawnNodes: the node to spawn has no name")
            return
        }
        
        self.removeAction(forKey: "spawnAction")
        self.enumerateChildNodes(withName: nodeName) { node, _ in
            node.removeAllActions()
            node.removeFromParent()
        }
        
        let spawnAction = SKAction.run {
            let newNode = nodeToSpawn.copy() as! SKNode
            newNode.position = spawnPosition
            parent.addChild(newNode)
            newNode.physicsBody?.applyImpulse(CGVector(dx: 0.2, dy: -0.1))
        }
        let waitAction = SKAction.wait(forDuration: interval)
        let sequenceAction = SKAction.sequence([spawnAction, waitAction])
        let repeatAction = SKAction.repeat(sequenceAction, count: count)

        parent.run(repeatAction, withKey: "spawnAction")
    }
    
    // MARK: - Update loop
    
    private var lastFrameTime: TimeInterval = 0
    private var frameCount = 0
    private var currentFPS = 0
    
    func getFrameRate(currentTime: TimeInterval) {
        frameCount += 1
        
        if currentTime - lastFrameTime >= 1 { // Calculate FPS every second
            currentFPS = frameCount
            frameCount = 0
            lastFrameTime = currentTime
            
            print("Current FPS: \(currentFPS)") // Or utilize this value
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        enumerateChildNodes(withName: "//velocity-ball") { node, _ in
            if let spriteNode = node as? SKSpriteNode,
               let physicsBody = spriteNode.physicsBody,
               spriteNode.shader == spriteNode.shader {
                
                let currentVelocity = physicsBody.velocity.length()
                let maxVelocity = CGFloat(500.0)
                let normalizedVelocity = max(0.01, min(currentVelocity / maxVelocity, 1.0))
                
                spriteNode.setValue(SKAttributeValue(float: Float(normalizedVelocity)), forAttribute: "a_velocity")
            }
        }
        
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.update()
        }
    }
    
    // MARK: - Touch events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let node = atPoint(location)
            if node.name == "button-spawn" {
                spawnNodes(
                    nodeToSpawn: velocityBall(),
                    spawnPosition: CGPoint(x: 0, y: 300),
                    interval: 0.01,
                    count: 100,
                    parent: self
                )
            }
        }
    }
}
