/**
 
 # Experimenting with SKShapeNode
 
 SpriteKit's shape nodes borrow largely from Core Graphics. You have access to powerful programmatic drawing capabilities.
 However, shape nodes are more expensive to draw that sprite nodes. Source:
 https://devstreaming-cdn.apple.com/videos/wwdc/2014/608xx0tzmkcqkrn/608/608_hd_best_practices_for_building_spritekit_games.mov
 Time: 45:18
 
 If the shape isn't meant to change, SKShapeNode can be used to create shapes programmatically,
 then the method `view.texture(from:)` can be used to generate a sprite from that shape.
 
 Created: 6 March 2024
 Updated: 12 Juin 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct ShapeNodes: View {
    var myScene = ShapeNodesScene()
    @State var selectedShape: ShapeToDraw = .VariousShapes
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                preferredFramesPerSecond: 120,
                options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
                debugOptions: [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount, .showsPhysics]
            )
            .ignoresSafeArea()
            .onAppear() {
                myScene.drawShape(selectedShape)
            }
            
            VStack {
                Picker("Select A Shape To Draw", selection: $selectedShape){
                    ForEach(ShapeToDraw.allCases) {shape in
                        Text(shape.rawValue).tag(shape)
                    }
                }
                .tint(.white)
                .pickerStyle(.automatic)
                .onChange(of: selectedShape) {
                    myScene.drawShape(selectedShape)
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    ShapeNodes()
}

// MARK: - Data

enum ShapeToDraw: String, CaseIterable, Identifiable {
    case CGAffineTransform
    case AnimatedGrid
    case Grid
    case CIFilters
    case PointingArrow
    case MarchingAnts
    case VariousShapes
    case ConcaveShapes
    case ShapeWithTextures
    
    var id: String {self.rawValue}
}

// MARK: - SpriteKit

class ShapeNodesScene: SKScene {
    
    var objectLayer = SKNode()
    
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .gray
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(
            x: -view.frame.width / 2,
            y: -view.frame.height / 2,
            width: view.frame.width,
            height: view.frame.height
        ))
        
        setupCamera()
        addChild(objectLayer)
    }
    
    func setupCamera() {
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.lockRotation = true
        camera = inertialCamera
        addChild(inertialCamera)
    }

    ///The function called by SwiftUI to select which shapes to draw
    func drawShape(_ function: ShapeToDraw) {
        let parent = objectLayer
        parent.removeAllChildren()
        
        switch function {
        case .CGAffineTransform:
            transformShapes(parent: parent)
        case .AnimatedGrid:
            createAnimatedGrid(cellSize: 60, rows: 5, cols: 5, parent: parent)
        case .Grid:
            createGrid(cellSize: 60, rows: 12, cols: 6, parent: parent)
        case .CIFilters:
            shapeWithFilters(parent: parent)
        case .PointingArrow:
            pointingArrow(parent: parent)
        case .MarchingAnts:
            marchingAnts(parent: parent)
        case .VariousShapes:
            variousShapes(parent: parent)
        case .ConcaveShapes:
            drawPath(parent: parent)
        case .ShapeWithTextures:
            shapeWithTexture(parent: parent)
        }
    }
    
    // MARK: CGAffineTransform
    
    func transformShapes(parent: SKNode) {
        let scaleX: CGFloat = 1
        let scaleY: CGFloat = 1
        
        let verticalShear: CGFloat = 0
        let horizontalShear: CGFloat = 1
        
        let translationX: CGFloat = 0
        let translationY: CGFloat = 0
        
        var transform = CGAffineTransform(
            a: scaleX,
            b: verticalShear,
            c: horizontalShear,
            d: scaleY,
            tx: translationX,
            ty: translationY
        )
        
        let rectangle: CGRect = CGRect(x: -50, y: -50, width: 100, height: 100)
        
        let rectanglePath = CGPath(rect: rectangle, transform: &transform)
        
        let shapeNode = SKShapeNode(path: rectanglePath)
        shapeNode.fillColor = .systemRed
        shapeNode.strokeColor = SKColor(white: 0, alpha: 1)
        shapeNode.lineWidth = 2
        shapeNode.isAntialiased = false
        
        parent.addChild(shapeNode)
        
        animateVerticalShear(of: shapeNode, from: -0.5, to: 0.5, duration: 2.0)
    }
    
    func animateVerticalShear(of shapeNode: SKShapeNode, from startValue: CGFloat, to endValue: CGFloat, duration: TimeInterval) {
        /// Store the start time
        var startTime: TimeInterval?
        
        /// Calculate the change needed
        let change = endValue - startValue
        
        /// Define the update block
        let updateBlock = { [weak self] in
            guard let self = self, let startTime = startTime else { return }
            let currentTime = CACurrentMediaTime()
            let elapsedTime = currentTime - startTime
            
            /// Calculate the current frame's value
            let elapsedTimeFraction = CGFloat(elapsedTime / duration)
            let currentValue = startValue + change * elapsedTimeFraction
            
            /// Update transform
            var transform = CGAffineTransform(a: 1, b: currentValue, c: currentValue, d: 1, tx: 0, ty: 0)
            let newPath = CGPath(rect: CGRect(x: -50, y: -50, width: 100, height: 100), transform: &transform)
            shapeNode.path = newPath
            
            /// Check if the animation should continue
            if elapsedTime > duration {
                self.removeAction(forKey: "shearAnimation")
                /// Optionally, reset or adjust the node after animation ends
                shapeNode.fillColor = .systemBlue
            }
        }
        
        /// Create a repeating action to apply the update block
        let animationAction = SKAction.repeatForever(SKAction.customAction(withDuration: duration, actionBlock: { _, _ in
            if startTime == nil {
                startTime = CACurrentMediaTime()
            }
            updateBlock()
        }))
        
        /// Run the animation action
        self.run(animationAction, withKey: "shearAnimation")
    }
    
    // MARK: Grid animation

    func createAnimatedGrid(cellSize: CGFloat, rows: Int, cols: Int, parent: SKNode) {
        let totalWidth = CGFloat(cols) * cellSize
        let totalHeight = CGFloat(rows) * cellSize
        let gridOrigin = CGPoint(x: -totalWidth / 2, y: -totalHeight / 2)
        
        var delay: TimeInterval = 0
        let animationDuration: TimeInterval = 0.2
        
        /// horizontal lines
        for row in (0...rows).reversed() {
            let start = CGPoint(x: gridOrigin.x, y: CGFloat(row) * cellSize + gridOrigin.y)
            let end = CGPoint(x: totalWidth + gridOrigin.x, y: CGFloat(row) * cellSize + gridOrigin.y)
            animateLine(from: start, to: end, delay: delay, duration: animationDuration, parent: parent)
            delay += animationDuration
        }
        
        /// vertical lines
        for col in 0...cols {
            let start = CGPoint(x: CGFloat(col) * cellSize + gridOrigin.x, y: totalHeight + gridOrigin.y)
            let end = CGPoint(x: CGFloat(col) * cellSize + gridOrigin.x, y: gridOrigin.y)
            animateLine(from: start, to: end, delay: delay, duration: animationDuration, parent: parent)
            delay += animationDuration
        }
    }
    
    func animateLine(from start: CGPoint, to end: CGPoint, delay: TimeInterval, duration: TimeInterval, parent: SKNode) {
        let path = CGMutablePath()
        path.move(to: start)
        
        let lineNode = SKShapeNode(path: path)
        lineNode.strokeColor = SKColor(white: 1, alpha: 1)
        lineNode.lineWidth = 0
        lineNode.lineCap = .square
        lineNode.isAntialiased = true
        
        parent.addChild(lineNode)
        
        /// animation to draw the line
        let drawAnimation = SKAction.customAction(withDuration: duration) { node, elapsedTime in
            guard let shapeNode = node as? SKShapeNode else { return }
            
            lineNode.lineWidth = 1
            let progress = elapsedTime / CGFloat(duration)
            let currentPoint = CGPoint(x: start.x + (end.x - start.x) * progress, y: start.y + (end.y - start.y) * progress)
            let currentPath = CGMutablePath()
            currentPath.move(to: start)
            currentPath.addLine(to: currentPoint)
            shapeNode.path = currentPath
        }
        
        let delayAction = SKAction.wait(forDuration: delay)
        let sequence = SKAction.sequence([delayAction, drawAnimation])
        lineNode.run(sequence)
    }

    // MARK: Generate grid
    
    func createGrid(cellSize: CGFloat, rows: Int, cols: Int, parent: SKNode) {
        let path = CGMutablePath()
        
        /// Calculate the total size of the grid
        let totalWidth = CGFloat(cols) * cellSize
        let totalHeight = CGFloat(rows) * cellSize
        
        /// Draw vertical lines
        for col in 0...cols {
            let x = CGFloat(col) * cellSize
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: totalHeight))
        }
        
        /// Draw horizontal lines
        for row in 0...rows {
            let y = CGFloat(row) * cellSize
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: totalWidth, y: y))
        }
        
        /// Add a background to the grid
        path.addRect(CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight))
        
        /// Create a shape node with the path
        let grid = SKShapeNode(path: path)
        grid.strokeColor = SKColor(white: 1, alpha: 1)
        grid.lineWidth = 1
        grid.lineCap = .square
        grid.isAntialiased = true
        grid.fillColor = SKColor(white: 1, alpha: 0.1)
        
        /// Center the grid lines within the node
        grid.position = CGPoint(x: -totalWidth / 2, y: -totalHeight / 2)
        
        parent.addChild(grid)
    }
    
    // MARK: Core Image filters
    
    func shapeWithFilters(parent: SKNode) {
        /// create a shape
        /// create Core Image filters and an effect node
        /// generate a texture from the effect node and use it as a physics body
        let ellipse = SKShapeNode(ellipseOf: CGSize(width: 100, height: 200))
        ellipse.lineWidth = 0
        ellipse.fillColor = .yellow
        
        let myFilter = CIFilter.gaussianBlur()
        myFilter.radius = 40
        
        let myFilter2 = CIFilter.bloom()
        myFilter2.intensity = 4
        
        let effectNode = SKEffectNode()
        effectNode.filter = myFilter
        effectNode.addChild(ellipse)
        effectNode.zRotation = 0.1
        
        if let path = ellipse.path {
            effectNode.physicsBody = SKPhysicsBody(polygonFrom: path)
        }
        
        parent.addChild(effectNode)
    }
    
    // MARK: Marching ants
    
    func pointingArrow(parent: SKNode) {
        let arrowPath = CGMutablePath()
        arrowPath.move(to: CGPoint(x: -100, y: 0))
        arrowPath.addLine(to: CGPoint(x: 100, y: 0))
        
        let arrowPath2 = CGMutablePath()
        arrowPath2.move(to: CGPoint(x: 100, y: 0))
        arrowPath2.addLine(to: CGPoint(x: 100, y: 20))
        arrowPath2.addLine(to: CGPoint(x: 140, y: 0))
        arrowPath.addPath(arrowPath2)
        
        let arrowPath3 = CGMutablePath()
        arrowPath3.move(to: CGPoint(x: 100, y: 0))
        arrowPath3.addLine(to: CGPoint(x: 100, y: -20))
        arrowPath3.addLine(to: CGPoint(x: 140, y: 0))
        arrowPath.addPath(arrowPath3)
        
        let arrowShape = SKShapeNode(path: arrowPath)
        arrowShape.lineWidth = 3
        arrowShape.fillColor = .red
        arrowShape.glowWidth = 0
        arrowShape.lineCap = .round
        arrowShape.lineJoin = .round
        arrowShape.zRotation = .pi/2
        arrowShape.isAntialiased = false
        parent.addChild(arrowShape)
        
        let dashes: [CGFloat] = [4, 8]
        var phase: CGFloat = 0
        
        let animateDashes = SKAction.run {
            phase -= 0.7
            let dashedArrowPath = arrowPath.copy(dashingWithPhase: phase, lengths: dashes)
            arrowShape.path = dashedArrowPath
        }
        let waitAction = SKAction.wait(forDuration: 1/60)
        let sequenceAction = SKAction.sequence([animateDashes, waitAction])
        
        arrowShape.run(SKAction.repeatForever(sequenceAction))
    }
    
    func marchingAnts(parent: SKNode) {
        /// create paths
        let rect = CGRect(x: -100, y: -100, width: 200, height: 200)
        let rectangularPath = CGPath(rect: rect, transform: nil)
        
        let circularPath = CGMutablePath()
        circularPath.addArc(
            center: CGPoint.zero,
            radius: 100,
            startAngle: 0,
            endAngle: CGFloat.pi * 2,
            clockwise: true
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
        let dashPattern: [CGFloat] = [5, 5]
        var phase: CGFloat = 0
        
        /// create a shape nodes
        let shapeNode = SKShapeNode()
        shapeNode.lineWidth = 3
        shapeNode.strokeColor = .white
        parent.addChild(shapeNode)
        
        let shapeNode2 = SKShapeNode()
        shapeNode2.lineWidth = 3
        shapeNode2.strokeColor = .white
        shapeNode2.position = CGPoint(x: 0, y: -250)
        parent.addChild(shapeNode2)
        
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
    
    // MARK: Basic shapes
    
    func variousShapes(parent: SKNode) {
        /// Built-in shapes
        let circle = SKShapeNode(circleOfRadius: 50)
        parent.addChild(circle)

        let ellipseOf = SKShapeNode(ellipseOf: CGSize(width: 100, height: 50))
        parent.addChild(ellipseOf)
        
        let ellipseIn = SKShapeNode(ellipseIn: CGRect(x: -25, y: -25, width: 50, height: 50))
        parent.addChild(ellipseIn)
        
        let rectangleOf = SKShapeNode(rect: CGRect(x: 50, y: 50, width: 100, height: 150))
        parent.addChild(rectangleOf)
        
        let roundRectangle = SKShapeNode(rect: CGRect(x: -150, y: 50, width: 100, height: 150), cornerRadius: 41)
        parent.addChild(roundRectangle)
        
        /// Shape with a path from rectangle
        let rectanglePath = CGMutablePath()
        rectanglePath.addRect(CGRect(x: -50, y: -50, width: 100, height: 100))
        let pathShape = SKShapeNode(path: rectanglePath)
        pathShape.strokeColor = .systemBlue
        pathShape.lineWidth = 4
        pathShape.lineJoin = .miter
        pathShape.miterLimit = .infinity
        pathShape.position = CGPoint(x: -100, y: -100)
        
        parent.addChild(pathShape)
        
        /// Shape with a centered path
        let circlePath = CGMutablePath()
        circlePath.addEllipse(in: CGRect(x: 0, y: 0, width: 100, height: 100))
        let pathCenteredShape = SKShapeNode(path: circlePath, centered: true)
        pathCenteredShape.strokeColor = .systemGreen
        pathCenteredShape.lineWidth = 2
        pathCenteredShape.position = CGPoint(x: 100, y: -100)
        
        parent.addChild(pathCenteredShape)
        
        /// Shape from points
        var points: [CGPoint] = [CGPoint(x: -50, y: -50), CGPoint(x: 0, y: 50), CGPoint(x: 50, y: -50)]
        let pointsShape = SKShapeNode(points: &points, count: points.count)
        pointsShape.strokeColor = SKColor.red
        pointsShape.lineWidth = 4
        pointsShape.lineCap = .round
        pointsShape.lineJoin = .round
        pointsShape.position = CGPoint(x: 0, y: 300)
        
        parent.addChild(pointsShape)
        
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
        pathFromPointsShape.position = CGPoint(x: 100, y: -300)
        
        parent.addChild(pathFromPointsShape)
        
        /// Shape from spline points
        /// pairs of points are joined with a quadratic curve
        var splinePoints: [CGPoint] = [
            CGPoint(x: -200, y: 0),
            CGPoint(x: 0, y: 25),
            CGPoint(x: 25, y: -25),
            CGPoint(x: 100, y: 50)
        ]
        let splineShape = SKShapeNode(splinePoints: &splinePoints, count: splinePoints.count)
        splineShape.strokeColor = SKColor.magenta
        splineShape.lineWidth = 4
        splineShape.position = CGPoint(x: 50, y: -200)
        parent.addChild((splineShape))
        
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
        shapeFromSplinePath.position = CGPoint(x: -50, y: -300)
        
        parent.addChild(shapeFromSplinePath)
    }
    
    // MARK: Sprite from shape
    
    func drawPath(parent: SKNode) {
        /// SpriteKit does not handle concave physics bodies for shapes
        /// We need to convert the shape into a sprite to do that
        let path1 = CGMutablePath()
        path1.move(to: CGPoint(x: 0, y: 0))
        path1.addLine(to: CGPoint(x: 0, y: 100))
        path1.addLine(to: CGPoint(x: 50, y: 60))
        path1.addLine(to: CGPoint(x: 100, y: 100))
        path1.addLine(to: CGPoint(x: 100, y: 0))
        path1.addLine(to: CGPoint(x: 50, y: 40))
        path1.closeSubpath()
        
        let shapeNode = SKShapeNode(path: path1, centered: true)
        shapeNode.lineWidth = 0
        shapeNode.fillColor = .systemGreen
        
        if let view = view, let shapeTexture = view.texture(from: shapeNode) {
            let sprite = SKSpriteNode(texture: shapeTexture)
            sprite.physicsBody = SKPhysicsBody(texture: shapeTexture, size: shapeTexture.size())
            sprite.position = CGPoint(x: 50, y: 50)
            parent.addChild(sprite)
        }
        
        /// But do not draw a path with lines that intersect, like this angled shape
        /// The physics body generation will likely fail
        let angledPath = CGMutablePath()
        angledPath.move(to: CGPoint(x: 0, y: 0))
        angledPath.addLine(to: CGPoint(x: 0, y: 100))
        angledPath.addLine(to: CGPoint(x: 100, y: 100))
        angledPath.addLine(to: CGPoint(x: 100, y: 50))
        angledPath.addLine(to: CGPoint(x: 50, y: 170))
        angledPath.addLine(to: CGPoint(x: 50, y: 0))
        angledPath.closeSubpath()
        
        let angledShape = SKShapeNode(path: angledPath)
        angledShape.lineWidth = 2
        angledShape.fillColor = .systemBlue
        
        if let view = view, let angledShapeTexture = view.texture(from: angledShape) {
            let sprite = SKSpriteNode(texture: angledShapeTexture)
            sprite.physicsBody = SKPhysicsBody(texture: angledShapeTexture, size: angledShapeTexture.size())
            sprite.position = CGPoint(x: -10, y: 200)
            sprite.alpha = 0.1
            parent.addChild(sprite)
        }
    }

    // MARK: Textured shapes
    
    func shapeWithTexture(parent: SKNode) {
        let myShape = SKShapeNode(rectOf: CGSize(width: 128, height: 128), cornerRadius: 20)
        myShape.lineWidth = 20
        myShape.fillColor = .systemOrange
        myShape.fillTexture = SKTexture(imageNamed: "SpriteKit")
        myShape.strokeTexture = SKTexture(imageNamed: "basketball-94")
        myShape.lineJoin = .miter
        myShape.strokeColor = .red
        parent.addChild((myShape))
    }
    
    // MARK: Helper functions
    
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
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.updateInertia()
        }
    }
    
    override func didSimulatePhysics() {
        //visualizeFrame(for: effectNode, in: self)
    }
}

class DashedLine: SKShapeNode {
    init(startPoint: CGPoint, endPoint: CGPoint, color: SKColor, width: CGFloat, dashLength: CGFloat, gap: CGFloat) {
        super.init()
        
        self.strokeColor = color
        
        let path = CGMutablePath()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        
        let shapeNode = SKShapeNode(path: path)
        shapeNode.strokeColor = color
        shapeNode.lineWidth = width
        
        let pattern: [CGFloat] = [dashLength, gap]
        let dashedPath = path.copy(dashingWithPhase: 0, lengths: pattern)
        
        self.path = dashedPath
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


