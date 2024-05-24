/**
 
 # Simulation Speed
 
 Exprimenting with SpriteKit scene speed.
 Animation speed applies to physics simulation and SKAction.
 
 This file also introduces:
 - Swift Observation
 - SwiftUI custom button styles
 
 Created: 19 December 2023
 Updated: 20 January 2024
 
 */

import SwiftUI
import SpriteKit
import Observation

// MARK: - SwiftUI

struct SimulationSpeed: View {
    @State private var myScene = SimulationSpeedScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                preferredFramesPerSecond: 120,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount]
            )
                .ignoresSafeArea()
            VStack {
                Spacer()
                VStack (spacing: 10) {
                    HStack {
                        let formattedSimulationSpeed = String(format: "%.1f", myScene.simulationAndAnimationSpeed)
                        Text("Speed " + formattedSimulationSpeed + "x")
                            .padding(.trailing)
                        Slider(
                            value: $myScene.simulationAndAnimationSpeed,
                            in: 0...3,
                            step: 0.1
                        )
                        .onChange(of: myScene.simulationAndAnimationSpeed) {
                            myScene.setSceneSpeed()
                        }
                    }
                    
                    HStack (spacing: 0) {
                        Text("Gravity:")
                            .padding(.trailing)
                        Button(action: {
                            myScene.setGravity(0.0)
                        }, label: {
                            Image("rocket-100")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        })
                        .buttonStyle(firstButtonStyle())
                        
                        Button(action: {
                            myScene.setGravity(-9.8)
                        }, label: {
                            Image("earth-100")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        })
                        .buttonStyle(firstButtonStyle())
                        
                        Button(action: {
                            myScene.setGravity(-1.62)
                        }, label: {
                            Image("crescent-100")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        })
                        .buttonStyle(firstButtonStyle())
                        
                        Button(action: {
                            myScene.setGravity(-24.79)
                        }, label: {
                            Image("jupiter-100")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                        })
                        .buttonStyle(firstButtonStyle())
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 0) {
                        Button(action: {
                            myScene.togglePlayPause()
                        }, label: {
                            let iconToDisplay = myScene.isScenePaused ? "play.fill.white" : "pause.fill.white"
                            Image(systemName: iconToDisplay)
                                .renderingMode(.template) // Apply renderingMode(.template) to allow color modification
                                .foregroundColor(.black)
                        })
                        .buttonStyle(firstButtonStyle())
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - SpriteKit

@Observable class SimulationSpeedScene: SKScene {
    
    var isScenePaused: Bool = true
    var simulationAndAnimationSpeed = 1.0
    var gravityY = -9.8
    
    // MARK: didLoad
    override func sceneDidLoad() {
    }
    
    // MARK: didMove
    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        size = view.bounds.size
        view.isMultipleTouchEnabled = true
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        isPaused = isScenePaused
        backgroundColor = .white
        
        physicsWorld.gravity = CGVector(dx: 0, dy: gravityY)
        physicsWorld.speed = simulationAndAnimationSpeed
        speed = simulationAndAnimationSpeed
        
        setupPhysicsBoundaries()
        createObjects()
    }
    
    func setupPhysicsBoundaries() {
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        borderBody.friction = 0
        borderBody.restitution = 0.5
        self.physicsBody = borderBody
    }
    
    // MARK: willMove
    override func willMove(from view: SKView) {
        print("SimulationSpeed.swift ➡️ willMove")
    }
    
    // MARK: didChange
    override func didChangeSize(_ oldSize: CGSize) {
        setupPhysicsBoundaries()
    }
    
    // MARK: Scene Objects
    func createObjects() {
        let spriteObject = SKSpriteNode(color: .red, size: CGSize(width: 60, height: 60))
        spriteObject.name = "draggable"
        spriteObject.position = CGPoint(x: 0, y: 300)
        spriteObject.physicsBody = SKPhysicsBody(rectangleOf: spriteObject.size)
        spriteObject.physicsBody?.restitution = 0.5
        spriteObject.physicsBody?.linearDamping = 0
        spriteObject.lightingBitMask = 0b0001
        spriteObject.shadowCastBitMask = 0b0001
        addChild(spriteObject)
        
        let shapeObject = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 5)
        shapeObject.name = "draggable"
        shapeObject.fillColor = .systemBlue
        shapeObject.strokeColor = .clear
        shapeObject.position = CGPoint(x: 0, y: 230)
        shapeObject.physicsBody = SKPhysicsBody(polygonFrom: shapeObject.path!)
        shapeObject.physicsBody?.restitution = 0.5
        shapeObject.physicsBody?.linearDamping = 0
        shapeObject.physicsBody?.pinned = true
        shapeObject.physicsBody?.density = 1000
        addChild(shapeObject)
        continuouslyRotate(shapeObject)
        
        let ground = SKSpriteNode(color: .darkGray, size: CGSize(width: 370, height: 10))
        ground.position = CGPoint(x: .zero, y: -190)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.affectedByGravity = false
        ground.physicsBody?.isDynamic = false
        addChild(ground)
        
        createGridOfShapes()
    }
    
    func createGridOfShapes() {
        let shapeRadius: CGFloat = 30
        let leftViewBound: CGFloat = -160
        let rightViewBound: CGFloat = 160
        let bottomViewBound: CGFloat = -100
        let topViewBound: CGFloat = 200
        for i in stride(from: leftViewBound, to: rightViewBound, by: shapeRadius*2) {
            for j in stride(from: bottomViewBound, to: topViewBound, by: shapeRadius*2) {
                let gridObject = SKShapeNode(rectOf: CGSize(width: shapeRadius*2, height: shapeRadius*2), cornerRadius: shapeRadius)
                gridObject.name = "draggable"
                gridObject.position = CGPoint(x: i, y: j)
                gridObject.fillColor = .systemYellow
                gridObject.strokeColor = .clear
                gridObject.physicsBody = SKPhysicsBody(polygonFrom: gridObject.path!)
                //addChild(gridObject)
                
                let anEffectNode = SKEffectNode()
                anEffectNode.addChild(gridObject)
                addChild(anEffectNode)
                anEffectNode.filter = ChainCIFilter(filters: [
                    
                ])
            }
        }
    }
    
    func createGridOfSprites() {
        let shapeRadius: CGFloat = 20
        let leftViewBound: CGFloat = -160
        let rightViewBound: CGFloat = 160
        let bottomViewBound: CGFloat = -100
        let topViewBound: CGFloat = 200
        
        for i in stride(from: leftViewBound, to: rightViewBound, by: shapeRadius*2) {
            for j in stride(from: bottomViewBound, to: topViewBound, by: shapeRadius*2) {
                let gridObject = SKShapeNode(rectOf: CGSize(width: shapeRadius*2, height: shapeRadius*2), cornerRadius: shapeRadius)
                gridObject.name = "draggable"
                gridObject.position = CGPoint(x: i, y: j)
                gridObject.fillColor = .systemYellow
                gridObject.strokeColor = .clear
                
                let shapeTexture = view?.texture(from: gridObject)
                let spriteGridObject = SKSpriteNode(texture: shapeTexture)
                spriteGridObject.physicsBody = SKPhysicsBody(texture: shapeTexture!, size: shapeTexture!.size())
                spriteGridObject.lightingBitMask = 0b0001
                spriteGridObject.shadowCastBitMask = 0b0001
                addChild(spriteGridObject)
            }
        }
    }
    
    // MARK: API
    
    func setSceneSpeed() {
        self.physicsWorld.speed = simulationAndAnimationSpeed
        self.speed = simulationAndAnimationSpeed
    }
    
    func setGravity(_ gravityY: CGFloat) {
        self.physicsWorld.gravity = CGVector(dx: 0, dy: gravityY)
    }
    
    func togglePlayPause() {
        isScenePaused.toggle()
        self.isPaused = isScenePaused
    }
    
    func continuouslyRotate(_ node: SKNode) {
        let rotateAction = SKAction.rotate(byAngle: -.pi * 2, duration: 1.0)
        let continuousRotation = SKAction.repeatForever(rotateAction)
        node.run(continuousRotation)
    }
    
    // MARK: Dragging objects
    
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
    SimulationSpeed()
}
