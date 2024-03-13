/**
 
 # Experimenting with SKShapeNode
 
 Created: 6 March 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct ShapeNodes: View {
    var myScene = ShapeNodesScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                preferredFramesPerSecond: 120,
                options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
                debugOptions: [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount, .showsPhysics]
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - SpriteKit

class ShapeNodesScene: SKScene {
    
    // MARK: Scene setup
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .darkGray
    }
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        scene?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scene?.position = CGPoint(x: 200, y: 0)
        physicsWorld.speed = 0
        let physicsBoundaries = CGRect(
            x: -view.frame.width / 2 + 40,
            y: -view.frame.height / 2 + 40,
            width: view.frame.width - 80,
            height: view.frame.height - 80
        )
        physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBoundaries)
        
        /// comment/uncomment to execute various examples
        //marchingAnts()
        //shapeWithTexture()
        drawPath()
    }
    
    // MARK: drawing paths
    let effectNode = SKEffectNode()
    
    func drawPath() {
        /// Sprite node from shape node
        let path1 = CGMutablePath()
        path1.move(to: CGPoint(x: 0, y: 0))
        path1.addLine(to: CGPoint(x: 0, y: 100))
        path1.addLine(to: CGPoint(x: 50, y: 60))
        path1.addLine(to: CGPoint(x: 100, y: 100))
        path1.addLine(to: CGPoint(x: 100, y: 0))
        path1.addLine(to: CGPoint(x: 50, y: 40))
        path1.closeSubpath()
        
        let shapeNode = SKShapeNode(path: path1)
        shapeNode.position = CGPoint(x: 50, y: 50)
        shapeNode.lineWidth = 2
        shapeNode.strokeColor = .clear
        shapeNode.fillColor = .white
        if let view = view, let shapeTexture = view.texture(from: shapeNode) {
            let sprite = SKSpriteNode(texture: shapeTexture)
            sprite.color = .systemGreen
            sprite.colorBlendFactor = 1
            sprite.physicsBody = SKPhysicsBody(texture: shapeTexture, size: shapeTexture.size())
            sprite.position = CGPoint(x: 0, y: 0)
            sprite.position = CGPoint(x: shapeNode.frame.midX, y: shapeNode.frame.midY)
            addChild(sprite)
        }
        addChild(shapeNode)
        
        /// An ellipse
        let ellipse = SKShapeNode(ellipseOf: CGSize(width: 100, height: 200))
        ellipse.lineWidth = 1
        ellipse.fillColor = .systemYellow
        if let path2 = ellipse.path {
            ellipse.physicsBody = SKPhysicsBody(polygonFrom: path2)
        }
        addChild(ellipse)
        
        /// A concave shape node
        let anglePath = CGMutablePath()
        anglePath.move(to: CGPoint(x: 0, y: 0))
        anglePath.addLine(to: CGPoint(x: 0, y: 100))
        anglePath.addLine(to: CGPoint(x: 100, y: 100))
        anglePath.addLine(to: CGPoint(x: 100, y: 50))
        anglePath.addLine(to: CGPoint(x: 50, y: 170))
        anglePath.addLine(to: CGPoint(x: 50, y: 0))
        anglePath.closeSubpath()
        
        let angleShape = SKShapeNode(path: anglePath)
        angleShape.fillColor = .systemBlue
        angleShape.physicsBody = SKPhysicsBody(polygonFrom: anglePath)
        angleShape.position = CGPoint(x: 0, y: 300)
        addChild(angleShape)
        
        visualizeFrame(for: angleShape, in: scene!)
    }
    
    // MARK: draw the bounding box of a frame
    func visualizeFrame(for targetNode: SKNode, in parent: SKNode) {
        let visualizationNodeName = "visualizationFrameNode"
        
        let existingVisualizationNode = parent.childNode(withName: visualizationNodeName) as? SKShapeNode
        
        let frame: CGRect = targetNode.calculateAccumulatedFrame()
        let path = CGPath(rect: frame, transform: nil)
        
        if let visualizationNode = existingVisualizationNode {
            visualizationNode.path = path
        } else {
            let frameNode = SKShapeNode(path: path)
            frameNode.name = visualizationNodeName
            frameNode.strokeColor = SKColor.red
            frameNode.zPosition = 100
            parent.addChild(frameNode)
        }
    }
    
    override func didSimulatePhysics() {
        //visualizeFrame(for: effectNode, in: self)
    }
    
    // MARK: Add texture to shape node
    func shapeWithTexture() {
        let myShape = SKShapeNode(rectOf: CGSize(width: 64, height: 64), cornerRadius: 12)
        myShape.position = CGPoint(x: 0, y: 200)
        myShape.lineWidth = 10
        myShape.fillColor = .blue
        myShape.fillTexture = SKTexture(imageNamed: "SpriteKit_128x128_2x")
        myShape.strokeTexture = SKTexture(imageNamed: "basketball-94")
        myShape.strokeColor = .red
        addChild((myShape))
    }
    
    // MARK: Marching Ants effect
    func marchingAnts() {
        /// create paths
        let rect = CGRect(x: -100, y: -100, width: 200, height: 200)
        let rectangularPath = CGPath(rect: rect, transform: nil)
        
        let circularPath = CGMutablePath()
        circularPath.addArc(center: CGPoint.zero,
                    radius: 100,
                            startAngle: 0,
                    endAngle: CGFloat.pi * 2,
                    clockwise: false)
        
        /// Define the dash pattern
        /// - Parameter lengths: x units of dash, x units of gap
        /// - Parameter dashingWithPhase: starting point of the dash pattern
        let dashPattern: [CGFloat] = [10, 5]
        var phase: CGFloat = 0
        
        /// create a shape nodes
        let shapeNode = SKShapeNode()
        shapeNode.lineWidth = 3
        shapeNode.strokeColor = .white
        addChild(shapeNode)
        
        let shapeNode2 = SKShapeNode()
        shapeNode2.lineWidth = 3
        shapeNode2.strokeColor = .white
        shapeNode2.position = CGPoint(x: 0, y: -250)
        addChild(shapeNode2)
        
        /// animate the phase parameter with SKAction
        let incrementDashingPhaseAction = SKAction.run {
            phase += 1
            let dashedCircularPath = circularPath.copy(dashingWithPhase: phase, lengths: dashPattern)
            shapeNode.path = dashedCircularPath
            
            let dashedRectangularPath = rectangularPath.copy(dashingWithPhase: phase, lengths: dashPattern)
            shapeNode2.path = dashedRectangularPath
        }
        
        let waitAction = SKAction.wait(forDuration: 0.02)
        let sequenceAction = SKAction.sequence([incrementDashingPhaseAction, waitAction])
        let repeatForeverAction = SKAction.repeatForever(sequenceAction)
        shapeNode.run(repeatForeverAction)
    }
}

#Preview {
    ShapeNodes()
}

