/**
 
 # Shaders Playground
 
 A playground file to experiment with shaders in SpriteKit.
 
 Achraf Kassioui
 Created: 21 April 2024
 Updated: 21 April 2024
 
 */

import SwiftUI
import SpriteKit
import CoreImage.CIFilterBuiltins

// MARK: - Live preview

struct ShadersPlaygroundView: View {
    @State private var sceneId = UUID()
    
    var body: some View {
        SpriteView(
            scene: ShadersPlaygroundScene(),
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
    ShadersPlaygroundView()
}

// MARK: - SpriteKit

class ShadersPlaygroundScene: SKScene {
    
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
        
        let backgroundTexture = generateGridTexture(cellSize: 60, rows: 30, cols: 30, color: SKColor(white: 0, alpha: 0.3))
        let background = SKSpriteNode(texture: backgroundTexture)
        background.zPosition = -1
        addChild(background)
        
        createButton()
        
        let labelNode = SKLabelNode(text: "Hello")
        labelNode.fontName = "Menlo-Bold"
        labelNode.verticalAlignmentMode = .center
        
        let effetNode = SKEffectNode()
        effetNode.addChild(labelNode)
        effetNode.physicsBody = SKPhysicsBody(rectangleOf: effetNode.calculateAccumulatedFrame().size)
        
        let shader = SKShader(source: """
        void main() {
            vec3 color = vec3(1.0, 0.0, 0.0);
            float alpha = texture2D(u_texture, v_tex_coord).a;
            gl_FragColor = vec4(color * alpha, alpha);
        }
        """)
        effetNode.shader = shader
        
        addChild(effetNode)
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
    
    // MARK: - Objects
    
    func labelNode() -> SKNode {
        let labelNode = SKLabelNode(text: "Hello")
        labelNode.fontName = "Menlo-Bold"
        labelNode.verticalAlignmentMode = .center
        
        let effetNode = SKEffectNode()
        effetNode.name = "label-node"
        effetNode.addChild(labelNode)
        effetNode.physicsBody = SKPhysicsBody(rectangleOf: effetNode.calculateAccumulatedFrame().size)
        
        let shader = SKShader(source: """
        void main() {
            vec3 color = vec3(1.0, 0.0, 0.0);
            float alpha = texture2D(u_texture, v_tex_coord).a;
            gl_FragColor = vec4(color * alpha, alpha);
        }
        """)
        effetNode.shader = shader
        
        return effetNode
    }
    
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
    
    override func update(_ currentTime: TimeInterval) {
        enumerateChildNodes(withName: "//label-node") { node, _ in
            if let nodeWithShader = node as? SKSpriteNode,
               let physicsBody = nodeWithShader.physicsBody {
                
                let currentVelocity = physicsBody.velocity.length()
                let maxVelocity = CGFloat(500.0)
                let normalizedVelocity = max(0.01, min(currentVelocity / maxVelocity, 1.0))
                
                nodeWithShader.setValue(SKAttributeValue(float: Float(normalizedVelocity)), forAttribute: "a_velocity")
            }
        }
        
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.updateInertia()
        }
    }
    
    // MARK: - Touch events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let node = atPoint(location)
            if node.name == "button-spawn" {
                spawnNodes(
                    nodeToSpawn: labelNode(),
                    spawnPosition: CGPoint(x: 0, y: 300),
                    interval: 0.01,
                    count: 10,
                    parent: self
                )
            }
        }
    }
}
