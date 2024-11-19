/**
 
 # SpriteKit Lighting
 
 Created: 23 January 2024
 
 */

import SwiftUI
import SpriteKit
import Observation

// MARK: - SwiftUI

struct Lighting: View {
    @State private var myScene = LightingScene()
    
    var body: some View {
        VStack (spacing: 0) {
            SpriteView(
                scene: myScene,
                preferredFramesPerSecond: 120,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount]
            )
            .ignoresSafeArea()
            VStack {
                HStack {
                    Slider(
                        value: $myScene.sliderValue,
                        in: 1...100,
                        step: 1
                    )
                    .onChange(of: myScene.sliderValue) {
                        myScene.applyImageFilters()
                    }
                }
                
                HStack (spacing: 20) {
                    Text("Slide ground")
                        .multilineTextAlignment(.trailing)
                    Slider(
                        value: $myScene.groundYPosition,
                        in: -300 ... 300,
                        step: 0.1
                    )
                    .onChange(of: myScene.groundYPosition) {
                        myScene.slideNode(myScene.ground, by: myScene.groundYPosition)
                    }
                }
                Toggle("Toggle Physics", isOn: $myScene.isPhysicsON)
                    .toggleStyle(SwitchToggleStyle(tint: .red))
                    .onChange(of: myScene.isPhysicsON) {
                        myScene.togglePhysics()
                    }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
}

// MARK: - SpriteKit

@Observable class LightingScene: SKScene {
    
    var isScenePaused = false
    var isPhysicsPrecise = false
    var isPhysicsON = true
    var sliderValue: Double = 0
    
    var myLight: SKLightNode!
    
    var ground: SKSpriteNode!
    var groundYPosition: Double = -200
    
    // MARK: didLoad
    override func sceneDidLoad() {
        createObjects()
    }
    
    // MARK: didMove
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        setupPhysicsBoundaries()
        self.isPaused = isScenePaused
        self.backgroundColor = .clear
        view.isMultipleTouchEnabled = true
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        self.physicsBody?.usesPreciseCollisionDetection = isPhysicsPrecise
        self.physicsWorld.speed = 1
        
        shouldEnableEffects = true
        shouldCenterFilter = true
    }
    
    private func setupPhysicsBoundaries() {
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        borderBody.friction = 0
        borderBody.restitution = 0.5
        self.physicsBody = borderBody
    }
    
    // MARK: willMove
    override func willMove(from view: SKView) {
        print("Lighting.swift ➡️ willMove")
    }
    
    // MARK: Scene Objects
    func createObjects() {
        let spriteObject = SKSpriteNode(color: .white, size: CGSize(width: 100, height: 40))
        spriteObject.name = "draggable"
        spriteObject.position = CGPoint(x: 0, y: 0)
        spriteObject.physicsBody = SKPhysicsBody(rectangleOf: spriteObject.size)
        spriteObject.physicsBody?.restitution = 0.5
        spriteObject.physicsBody?.linearDamping = 0
        spriteObject.physicsBody?.angularDamping = 0
        spriteObject.physicsBody?.density = 10
        spriteObject.lightingBitMask = 0b0001
        spriteObject.shadowCastBitMask = 0b0001
        addChild(spriteObject)
        continuouslyRotate(spriteObject)
        
        ground = SKSpriteNode(color: .darkGray, size: CGSize(width: 390, height: 50))
        ground.name = "draggable"
        ground.position = CGPoint(x: .zero, y: groundYPosition)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.usesPreciseCollisionDetection = isPhysicsPrecise
        ground.physicsBody?.affectedByGravity = false
        ground.physicsBody?.isDynamic = false
        addChild(ground)
        
        // Create a light
        let lightContainer = SKShapeNode(circleOfRadius: 30)
        lightContainer.name = "draggable"
        lightContainer.fillColor = .white
        lightContainer.strokeColor = .clear
        lightContainer.position = CGPoint(x: 0, y: 220)
        lightContainer.fillColor = .white
        myLight = SKLightNode()
        //myLight.zPosition = 1000
        myLight.categoryBitMask = 0b0001
        myLight.lightColor = .white
        myLight.ambientColor = SKColor(white: 0.4, alpha: 1)
        lightContainer.addChild(myLight)
        addChild(lightContainer)
        
        let myText = SKLabelNode(text: "Hello World")
        myText.position = CGPoint(x: 0, y: 100)
        myText.name = "draggable"
        myText.fontName = "Impact"
        myText.fontColor = .systemYellow
        myText.fontSize = 60
        myText.zPosition = 100
        addChild(myText)
        
        createGridOfSprites()
    }
    
    func createGridOfSprites() {
        let gap: CGFloat = 80
        let leftViewBound: CGFloat = -160
        let rightViewBound: CGFloat = 160
        let bottomViewBound: CGFloat = -100
        let topViewBound: CGFloat = 200
        
        for i in stride(from: leftViewBound, to: rightViewBound, by: gap) {
            for j in stride(from: bottomViewBound, to: topViewBound, by: gap) {
                let _texture = SKTexture(imageNamed: "circle-30-fill")
                let physics_size = CGSize(width: _texture.size().width - 3, height: _texture.size().height - 3 )
                let gridObject = SKSpriteNode(texture: _texture)
                gridObject.name = "draggable"
                gridObject.position = CGPoint(x: i, y: j)
                gridObject.physicsBody = SKPhysicsBody(texture: _texture, size: physics_size)
                gridObject.physicsBody?.usesPreciseCollisionDetection = isPhysicsPrecise
                gridObject.lightingBitMask = 0b0001
                gridObject.shadowCastBitMask = 0b0001
                gridObject.setScale(1.5)
                addChild(gridObject)
            }
        }
    }
    
    // MARK: API
    func slideNode(_ node: SKNode, by: CGFloat) {
        groundYPosition = by
        node.position.y = groundYPosition
    }
    
    func continuouslyRotate(_ node: SKNode) {
        let rotateAction = SKAction.rotate(byAngle: -.pi * 2, duration: 1.0)
        let continuousRotation = SKAction.repeatForever(rotateAction)
        node.run(continuousRotation)
    }
    
    func togglePhysics() {
        if (isPhysicsON) {
            physicsWorld.speed = 1
        } else {
            physicsWorld.speed = 0
        }
    }
    
    func applyImageFilters() {
        filter  = ChainCIFilter(filters: [
            CIFilter(name: "CIZoomBlur", parameters: [
                "inputAmount": sliderValue,
                "inputCenter": CIVector(x: 400, y: 600)
            ])
        ])
    }
    
    // MARK: Multi touch dragging
    
    var selectedNodes: [UITouch: SKNode] = [:]
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = self.atPoint(location)
                if (touchedNode.name == "draggable") {
                    selectedNodes[touch] = touchedNode
                }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if let selectedNode = selectedNodes[touch] {
                selectedNode.position = location
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            selectedNodes.removeValue(forKey: touch)
        }
    }
}

#Preview {
    Lighting()
}

