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
        //variousShapes()
        //marchingAnts()
        //shapeWithTexture()
        //drawPath()
        pointingArrow()
    }
    
    func pointingArrow() {
        let arrowPath = CGMutablePath()
        
        arrowPath.move(to: CGPoint(x: -100, y: 0))
        arrowPath.addLine(to: CGPoint(x: 100, y: 0))
        arrowPath.addLine(to: CGPoint(x: 100, y: 20))
        arrowPath.addLine(to: CGPoint(x: 140, y: 0))
        
        let arrowPath2 = CGMutablePath()
        arrowPath2.move(to: CGPoint(x: 100, y: 0))
        arrowPath2.addLine(to: CGPoint(x: 100, y: -20))
        arrowPath2.addLine(to: CGPoint(x: 140, y: 0))
        
        arrowPath.addPath(arrowPath2)
        
        let arrowShape = SKShapeNode(path: arrowPath)
        arrowShape.lineWidth = 2
        arrowShape.glowWidth = 0
        arrowShape.lineCap = .round
        arrowShape.lineJoin = .round
        addChild(arrowShape)
        
        let dashes: [CGFloat] = [8, 6]
        var phase: CGFloat = 0
        var colorBlink: Bool = false
        
        let animateDashes = SKAction.run {
            phase -= 1
            let dashedArrowPath = arrowPath.copy(dashingWithPhase: phase, lengths: dashes)
            if colorBlink { arrowShape.strokeColor = .white }
            else { arrowShape.strokeColor = .black }
            colorBlink.toggle()
            arrowShape.path = dashedArrowPath
        }
        let waitAction = SKAction.wait(forDuration: 0.08)
        let sequenceAction = SKAction.sequence([animateDashes, waitAction])
        
        arrowShape.run(SKAction.repeatForever(sequenceAction))
    }
    
    // MARK: Various shapes
    func variousShapes() {
        /// Basic shapes
        let circle = SKShapeNode(circleOfRadius: 50)
        addChild(circle)

        let ellipseOf = SKShapeNode(ellipseOf: CGSize(width: 100, height: 10))
        addChild(ellipseOf)
        
        let ellipseIn = SKShapeNode(ellipseIn: CGRect(x: -25, y: -25, width: 50, height: 50))
        addChild(ellipseIn)
        
        let rectangleOf = SKShapeNode(rect: CGRect(x: 50, y: 50, width: 100, height: 150))
        addChild(rectangleOf)
        
        let roundRectangle = SKShapeNode(rect: CGRect(x: -150, y: 50, width: 100, height: 150), cornerRadius: 41)
        addChild(roundRectangle)
        
        /// Shape with a path from rectangle
        let rectanglePath = CGMutablePath()
        rectanglePath.addRect(CGRect(x: -50, y: -50, width: 100, height: 100))
        let pathShape = SKShapeNode(path: rectanglePath)
        pathShape.strokeColor = .blue
        pathShape.lineWidth = 2
        addChild(pathShape)
        pathShape.position = CGPoint(x: -100, y: -100)
        
        /// Shape with a centered path
        let circlePath = CGMutablePath()
        circlePath.addEllipse(in: CGRect(x: 0, y: 0, width: 100, height: 100))
        let pathCenteredShape = SKShapeNode(path: circlePath, centered: true)
        pathCenteredShape.strokeColor = .green
        pathCenteredShape.lineWidth = 2
        addChild(pathCenteredShape)
        pathCenteredShape.position = CGPoint(x: 100, y: -100)
        
        /// Shape from points
        var points: [CGPoint] = [CGPoint(x: -50, y: -50), CGPoint(x: 0, y: 50), CGPoint(x: 50, y: -50)]
        let pointsShape = SKShapeNode(points: &points, count: points.count)
        pointsShape.strokeColor = SKColor.red
        pointsShape.lineWidth = 2
        addChild(pointsShape)
        pointsShape.position = CGPoint(x: 0, y: 300)
        
        /// Shape with path from points, to create physics body with volume
        /// Volume physics bodies can be static or dynamic, and can interact with both volume and edge based physics bodies
        let pathPoints: [CGPoint] = [CGPoint(x: -50, y: -50), CGPoint(x: 0, y: 50), CGPoint(x: 50, y: -50)]
        let path = CGMutablePath()
        path.addLines(between: pathPoints)
        path.closeSubpath()
        
        let pathFromPointsShape = SKShapeNode(path: path)
        pathFromPointsShape.strokeColor = .orange
        pathFromPointsShape.lineWidth = 2
        
        pathFromPointsShape.physicsBody = SKPhysicsBody(polygonFrom: path)
        addChild(pathFromPointsShape)
        pathFromPointsShape.position = CGPoint(x: 100, y: -300)
        
        /// Shape from spline points
        /// pairs of points are joined with a quadratic curve
        var splinePoints: [CGPoint] = [CGPoint(x: -50, y: 0), CGPoint(x: -25, y: 25), CGPoint(x: 25, y: 25), CGPoint(x: 50, y: 0)]
        let splineShape = SKShapeNode(splinePoints: &splinePoints, count: splinePoints.count)
        splineShape.strokeColor = SKColor.magenta
        splineShape.lineWidth = 2
        addChild((splineShape))
        splineShape.position = CGPoint(x: 50, y: -200)
        
        /// Shape with path from spline points, to create an edge chain physics body
        /// Edge chain physics bodies can only be static, and do not interact with other edge based physics bodies
        let splinePointsForPath: [CGPoint] = [
            CGPoint(x: -100, y: 0),
            CGPoint(x: -50, y: 50),
            CGPoint(x: 0, y: 0),
            CGPoint(x: 50, y: -50),
            CGPoint(x: 100, y: 0)
        ]
        
        let pathFromSplinePoints = CGMutablePath()
        pathFromSplinePoints.move(to: splinePointsForPath.first!)
        pathFromSplinePoints.addCurve(to: splinePointsForPath[1], control1: splinePointsForPath[2], control2: splinePointsForPath[3])
        
        let shapeFromSplinePath = SKShapeNode(path: pathFromSplinePoints)
        shapeFromSplinePath.strokeColor = SKColor(white: 1, alpha: 1)
        shapeFromSplinePath.lineWidth = 2
        
        shapeFromSplinePath.physicsBody = SKPhysicsBody(edgeChainFrom: pathFromSplinePoints)
        shapeFromSplinePath.physicsBody?.isDynamic = true
        addChild(shapeFromSplinePath)
        shapeFromSplinePath.position = CGPoint(x: -50, y: -300)
    }
    
    // MARK: drawing paths
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
        
        let shapeNode = SKShapeNode(path: path1, centered: true)
        shapeNode.position = CGPoint(x: 50, y: 50)
        shapeNode.lineWidth = 2
        shapeNode.strokeColor = .clear
        shapeNode.fillColor = .white
        shapeNode.physicsBody = SKPhysicsBody(polygonFrom: path1)
        if let view = view, let shapeTexture = view.texture(from: shapeNode) {
            let sprite = SKSpriteNode(texture: shapeTexture)
            sprite.color = .systemGreen
            sprite.colorBlendFactor = 1
            sprite.physicsBody = SKPhysicsBody(texture: shapeTexture, size: shapeTexture.size())
            sprite.position = CGPoint(x: 0, y: 0)
            sprite.position = CGPoint(x: shapeNode.frame.midX, y: shapeNode.frame.midY)
            //addChild(sprite)
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
    
    // MARK: Visualize frame
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
    
    // MARK: Marching Ants
    func marchingAnts() {
        /// create paths
        let rect = CGRect(x: -100, y: -100, width: 200, height: 200)
        let rectangularPath = CGPath(rect: rect, transform: nil)
        
        let circularPath = CGMutablePath()
        circularPath.addArc(
            center: CGPoint.zero,
            radius: 100,
            startAngle: 0,
            endAngle: CGFloat.pi * 2,
            clockwise: false
        )
        circularPath.addArc(
            center: CGPoint(x: 0, y: 0),
            radius: 40,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: false
        )
        
        /// Define the dash pattern
        /// - Parameter lengths: x units of dash, x units of gap
        /// - Parameter dashingWithPhase: starting point of the dash pattern
        let dashPattern: [CGFloat] = [1, 5]
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

