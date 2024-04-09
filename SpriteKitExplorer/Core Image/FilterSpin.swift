/**
 
 # Automatic Image Filter
 
 Created: 26 March 2024
 Updated: 27 March 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - Live preview

struct FilterSpinView: View {
    var myScene = FilterSpinScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS]
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    FilterSpinView()
}

// MARK: - Scene setup

class FilterSpinScene: SKScene {
    
    override func didMove(to view: SKView) {
        isPaused = false
        isPaused = true
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .gray
        setupCamera(view)
        createUI()
        createColorWheel(view: view, randomPosition: false)
    }
    
    func setupCamera(_ view: SKView) {
        let camera = SKCameraNode()
        camera.name = "camera-main"
        camera.xScale = (view.bounds.size.width / size.width)
        camera.yScale = (view.bounds.size.height / size.height)
        scene?.camera = camera
        camera.setScale(1)
        
        addChild(camera)
    }
    
    // MARK: - Create objects
    
    var gaussiantBlur = CIFilter.gaussianBlur()
    
    func createColorWheel(view: SKView, randomPosition: Bool) {
        let colorWheelTexture = SKTexture(imageNamed: "color-wheel-1")
        let halfViewWidth = view.bounds.width / 2
        let halfViewHeight = view.bounds.height / 2
        
        for _ in 1...1 {
            let colorWheel = SKSpriteNode(texture: colorWheelTexture)
            colorWheel.name = "color-wheel"
            colorWheel.setScale(1)
            
            colorWheel.physicsBody = SKPhysicsBody(texture: colorWheelTexture, size: colorWheelTexture.size())
            colorWheel.physicsBody?.affectedByGravity = false
            colorWheel.physicsBody?.density = 1
            colorWheel.physicsBody?.collisionBitMask = 0
            colorWheel.physicsBody?.angularDamping = 0
            colorWheel.physicsBody?.density = 1
            
            let effectNode = SKEffectNode()
            effectNode.name = "effect-node"
            effectNode.zPosition = 10
            effectNode.filter = gaussiantBlur
            gaussiantBlur.radius = 0
            effectNode.addChild(colorWheel)
            
            if randomPosition {
                effectNode.position = CGPoint(
                    x: CGFloat.random(in: -halfViewWidth...halfViewWidth),
                    y: CGFloat.random(in: -halfViewHeight...halfViewHeight)
                )
            } else {
                effectNode.position = CGPoint.zero
            }
            
            addChild(effectNode)
        }
    }
    
    // MARK: - User interface
    
    func createUI() {
        let sceneStateLabel = SKLabelNode(text: "Play")
        sceneStateLabel.name = "button-scene-state-label"
        sceneStateLabel.fontName = "GillSans"
        sceneStateLabel.fontSize = 20
        sceneStateLabel.fontColor = SKColor(white: 1, alpha: 0.6)
        sceneStateLabel.position.y = -6
        sceneStateLabel.zPosition = 999
        
        let sceneStateButton = SKShapeNode(rectOf: CGSize(width: 180, height: 44), cornerRadius: 12)
        sceneStateButton.name = "button-scene-state"
        sceneStateButton.fillColor = SKColor(white: 0, alpha: 0.1)
        sceneStateButton.strokeColor = SKColor(white: 0, alpha: 0.3)
        sceneStateButton.addChild(sceneStateLabel)
        sceneStateButton.position = CGPoint(x: 0, y: -360)
        sceneStateButton.zPosition = 999
        
        addChild(sceneStateButton)
        
        let stopLabel = SKLabelNode(text: "Brake")
        stopLabel.name = "button-stop-label"
        stopLabel.fontName = "GillSans"
        stopLabel.fontSize = 20
        stopLabel.fontColor = SKColor(white: 0, alpha: 1)
        stopLabel.position.y = -6
        
        let stopButton = SKShapeNode(rectOf: CGSize(width: 80, height: 60), cornerRadius: 7)
        stopButton.name = "button-stop"
        stopButton.fillColor = SKColor(white: 1, alpha: 0.6)
        stopButton.addChild(stopLabel)
        stopButton.position = CGPoint(x: -50, y: -280)
        stopButton.zPosition = 999
        
        addChild(stopButton)
        
        let spinLabel = SKLabelNode(text: "Spin")
        spinLabel.name = "button-spin-label"
        spinLabel.fontName = "GillSans"
        spinLabel.fontSize = 20
        spinLabel.fontColor = SKColor(white: 0, alpha: 1)
        spinLabel.position.y = -6
        
        let spinButton = SKShapeNode(circleOfRadius: 40)
        spinButton.name = "button-spin"
        spinButton.fillColor = SKColor(white: 1, alpha: 0.6)
        spinButton.addChild(spinLabel)
        spinButton.position = CGPoint(x: 50, y: -280)
        spinButton.zPosition = 999
        
        addChild(spinButton)
    }
    
    // MARK: - User interaction
    
    func updateSceneState() {
        isPaused.toggle()
        if let label = childNode(withName: "//button-scene-state-label") as? SKLabelNode {
            label.text = isPaused ? "Play" : "Pause"
        }
    }
    
    func applyBrake(to node: SKNode) {
        guard let physicsBody = node.physicsBody else { return }

        let brakeStrength: CGFloat = 0.75

        physicsBody.angularVelocity *= brakeStrength

        let minimumVelocityToStop: CGFloat = 0.1
        if abs(physicsBody.angularVelocity) < minimumVelocityToStop {
            physicsBody.angularVelocity = 0
        }
    }
    
    func spin(node: SKNode) {
        guard let physicsBody = node.physicsBody else { return }
        
        let acceleration: CGFloat = 1.1
        let initialPush: CGFloat = 1
        
        if abs(physicsBody.angularVelocity) > 0.1 {
            physicsBody.angularVelocity *= acceleration
        } else {
            physicsBody.angularVelocity = initialPush
        }
    }
    
    // MARK: - Update loop
    
    override func update(_ currentTime: TimeInterval) {
        if let colorWheel = childNode(withName: "//color-wheel") as? SKSpriteNode,
           let body = colorWheel.physicsBody {
            gaussiantBlur.radius = 0.2 * Float(abs(body.angularVelocity))
        }
        
    }
    // MARK: - Events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            let touchedNodes = nodes(at: touchLocation)
            
            for node in touchedNodes {
                if node.name == "button-scene-state" {
                    updateSceneState()
                }
                
                if node.name == "button-spin" {
                    enumerateChildNodes(withName: "//color-wheel") { node, _ in
                        self.spin(node: node)
                    }
                }
                
                if node.name == "button-stop" {
                    enumerateChildNodes(withName: "//color-wheel") { node, _ in
                        self.applyBrake(to: node)
                    }
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
