/**
 
 # Action Playground
 
 A playground file to experiment with SKAction in SpriteKit.
 
 Achraf Kassioui
 Created: 22 April 2024
 Updated: 5 Junel 2024
 
 ## Findings
 
 - Assigning actions to particles doesn't work: the `particleAction` property is broken
 - Can build advanced animations using the follow path action
 
 */

import SwiftUI
import SpriteKit
import CoreImage.CIFilterBuiltins

// MARK: - SwiftUI

struct ActionsPlaygroundView: View {
    @State private var sceneId = UUID()
    @State private var isPaused = false
    @State private var isGravityON = true
    @State private var isCameraLocked = false
    var myScene = ActionsPlaygroundScene()
    
    var body: some View {
        VStack(spacing: 0) {
            SpriteView(
                scene: myScene,
                options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes]
            )
            .id(sceneId)
            .onAppear {
                sceneId = UUID()
            }
            .ignoresSafeArea()
            
            VStack {
                menuBar()
            }
        }
        .background(Color(SKColor.gray))
    }
    
    private func menuBar() -> some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                cameraLockButton
                gravityButton
                playPauseButton
                debugButton
                Spacer()
            }
        }
        .padding([.top, .leading, .trailing], 10)
        .background(.ultraThinMaterial)
        .shadow(radius: 10)
    }
    
    private var cameraLockButton: some View {
        Button(action: {
            isCameraLocked.toggle()
            myScene.lockCamera(isCameraLocked)
        }) {
            Image(isCameraLocked ? "camera-lock-icon" : "camera-unlock-icon").colorInvert()
        }
        .buttonStyle(roundButtonStyle())
    }
    
    
    private var gravityButton: some View {
        Button(action: {
            isGravityON.toggle()
            myScene.sceneGravity = isGravityON
        }) {
            Image(isGravityON ? "gravity-icon" : "gravity-off-icon").colorInvert()
        }
        .buttonStyle(roundButtonStyle())
    }
    
    private var playPauseButton: some View {
        Button(action: {
            isPaused.toggle()
            myScene.pauseScene(isPaused)
        }) {
            Image(systemName: isPaused ? "play.fill" : "pause.fill")
        }
        .buttonStyle(roundButtonStyle())
    }
    
    private var debugButton: some View {
        Button(action: {
            if let view = myScene.view {
                myScene.toggleDebugOptions(view: view, extended: true)
            }
        }) {
            Image("chart-bar-icon").colorInvert()
        }
        .buttonStyle(roundButtonStyle())
    }
}

#Preview {
    ActionsPlaygroundView()
}

// MARK: - SpriteKit

class ActionsPlaygroundScene: SKScene, InertialCameraDelegate {
    
    override func didMove(to view: SKView) {
        size = CGSize(width: view.bounds.width, height: view.bounds.height)
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        backgroundColor = SKColor.gray
        physicsWorld.gravity = CGVector(dx: 0, dy: -50)
        /// this is required when SKScene filters are enabled
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        cleanPhysics()
        
        setupCamera(scale: 1)
        createSceneLayers()
        createGrid(parent: objectsLayer)
        createZoomLabel(view: view, parent: uiLayer)
        createPhysicalBoundaryForUIBodies(view: view, UILayer: uiLayer)
        createPhysicalBoundaryForSceneBodies(rectangle: self.frame, parent: objectsLayer)
        
        actionsWithPhysics(view: view, parent: objectsLayer)
    }
    
    // MARK: - Scene Setup
    
    func createGrid(parent: SKNode) {
        let backgroundTexture = generateGridTexture(cellSize: 75, rows: 30, cols: 30, linesColor: SKColor(white: 0, alpha: 0.3))
        let background = SKSpriteNode(texture: backgroundTexture)
        background.zPosition = -1
        parent.addChild(background)
    }
    
    var sceneGravity = true {
        didSet {
            if sceneGravity == true { self.physicsWorld.gravity = CGVector(dx: 0, dy: -20) }
            else { self.physicsWorld.gravity = CGVector(dx: 0, dy: 0) }
        }
    }
    
    var physicsSimulation = true {
        didSet {
            if physicsSimulation { self.physicsWorld.speed = 1 }
            else { self.physicsWorld.speed = 0 }
        }
    }
    
    let uiLayer = SKNode()
    let effectLayer = SKEffectNode()
    let objectsLayer = SKNode()
    var zoomLabel = SKLabelNode()
    
    func pauseScene(_ isPaused: Bool) {
        self.objectsLayer.isPaused = isPaused
        self.physicsWorld.speed = isPaused ? 0 : 1
    }
    
    func createSceneLayers() {
        guard let camera = camera else {
            print("There is no camera in scene. App may crash.")
            return
        }
        
        uiLayer.zPosition = 9999
        camera.addChild(uiLayer)
        
        effectLayer.zPosition = 0
        effectLayer.shouldEnableEffects = false
        addChild(effectLayer)
        
        let myFilter = CIFilter.gaussianBlur()
        effectLayer.filter = ChainCIFilter(filters: [
            myFilter
        ])
        
        objectsLayer.zPosition = 1
        effectLayer.addChild(objectsLayer)
    }
    
    // MARK: - Camera
    
    func cameraWillScale(to scale: (x: CGFloat, y: CGFloat)) {
        
    }
    
    func cameraDidScale(to scale: (x: CGFloat, y: CGFloat)) {
        
    }
    
    func cameraDidMove(to position: CGPoint) {
        
    }
    
    func lockCamera(_ lock: Bool) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.lock = lock
        }
    }
    
    func setupCamera(scale: CGFloat) {
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.delegate = self
        inertialCamera.lockRotation = true
        inertialCamera.setTo(position: .zero, xScale: scale, yScale: scale, rotation: 0)
        camera = inertialCamera
        addChild(inertialCamera)
    }
    
    func createZoomLabel(view: SKView, parent: SKNode) {
        zoomLabel.name = "zoomLabel"
        zoomLabel.numberOfLines = 0
        zoomLabel.verticalAlignmentMode = .center
        zoomLabel.horizontalAlignmentMode = .center
        zoomLabel.position.y = view.bounds.height/2 - zoomLabel.calculateAccumulatedFrame().height/2 - view.safeAreaInsets.top - 20
        zoomLabel.isUserInteractionEnabled = false
        parent.addChild(zoomLabel)
    }
    
    struct TextStyleUIOverlay {
        static let paragraphStyle: NSMutableParagraphStyle = {
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            style.lineHeightMultiple = 1.2
            return style
        }()
        
        static let textShadow: NSShadow = {
            let shadow = NSShadow()
            shadow.shadowOffset = CGSize(width: 0, height: 0)
            shadow.shadowColor = SKColor.black
            shadow.shadowBlurRadius = 10
            return shadow
        }()
        
        static let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .baselineOffset: 20,
            .paragraphStyle: TextStyleUIOverlay.paragraphStyle,
            .foregroundColor: SKColor(white: 1, alpha: 0.8),
            .shadow: TextStyleUIOverlay.textShadow
        ]
    }
    
    func updateZoomLabel() {
        guard let camera = camera else { return }
        
        let zoomPercentage = 100 / (camera.xScale)
        let text = String(format: "Zoom: %.0f%%", zoomPercentage)
        
        zoomLabel.attributedText = NSAttributedString(string: text, attributes: TextStyleUIOverlay.attributes)
    }
    
    // MARK: - Physics and constraints
    
    func createPhysicalBoundaryForSceneBodies(rectangle: CGRect, parent: SKNode) {
        let boundaryForSceneBodies = SKShapeNode(rect: rectangle)
        boundaryForSceneBodies.lineWidth = 2
        boundaryForSceneBodies.strokeColor = SKColor(white: 0, alpha: 1)
        boundaryForSceneBodies.physicsBody = SKPhysicsBody(edgeLoopFrom: rectangle)
        setupPhysicsCategories(node: boundaryForSceneBodies, as: .sceneBoundary)
        //boundaryForSceneBodies.physicsBody?.restitution = 0
        boundaryForSceneBodies.zPosition = -1
        parent.addChild(boundaryForSceneBodies)
    }
    
    func createPhysicalBoundaryForUIBodies(view: SKView, UILayer: SKNode) {
        let bodyExtension: CGFloat = -10
        let uiArea = CGRect(
            x: -view.bounds.width/2 - bodyExtension/2,
            y: -view.bounds.height/2 - bodyExtension/2,
            width: view.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right + bodyExtension,
            height: view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom + bodyExtension
        )
        
        let uiAreaFrame = SKShapeNode(rect: uiArea)
        uiAreaFrame.lineWidth = 0
        uiAreaFrame.physicsBody = SKPhysicsBody(edgeLoopFrom: uiArea)
        setupPhysicsCategories(node: uiAreaFrame, as: .UIBoundary)
        uiAreaFrame.alpha = 0
        UILayer.addChild(uiAreaFrame)
    }
    
    func createSceneConstraints(node: SKNode, insideRect: SKNode) -> SKConstraint {
        let xRange = SKRange(lowerLimit: insideRect.frame.minX + node.frame.size.width / 2,
                             upperLimit: insideRect.frame.maxX - node.frame.size.width / 2)
        let yRange = SKRange(lowerLimit: insideRect.frame.minY + node.frame.size.height / 2,
                             upperLimit: insideRect.frame.maxY - node.frame.size.height / 2)
        
        let constraint = SKConstraint.positionX(xRange, y: yRange)
        constraint.referenceNode = insideRect
        return constraint
    }
    
    // MARK: - Actions
    
    func createActionBody(parent: SKNode) {
        guard let camera = camera else { return }
        
        let rectangle = createRoundedRectangle(size: CGSize(width: 60, height: 60), color: .systemRed, name: "flickable")
        parent.addChild(rectangle)
        
        let myAction = SKAction.screenZoomWithNode(camera, amount: CGPoint(x: -1, y: -1), oscillations: 1, duration: 0.5)
        
        rectangle.run(SKAction.repeatForever(myAction))
    }
    
    struct ActionsCatalog {
        
        static let scene = SKScene()
        static let node = SKSpriteNode()
        static let path = CGMutablePath()
        
        let myAction2 = SKAction.colorGlitchWithScene(scene, originalColor: .gray, duration: 1)
        let myAction3 = SKAction.follow(path, asOffset: false, orientToPath: true, duration: 2)
        let myAction4 = SKAction.screenShakeWithNode(node, amount: CGPoint(x: 0, y: 1), oscillations: 100, duration: 5)
        let action = SKAction.follow(path, asOffset: false, orientToPath: true, speed: 1500)
        
        let rotateAction = SKEase.rotate(easeFunction: .curveTypeElastic, easeType: .easeTypeOut, time: 1, from: .pi*0.125, to: 0)
        let moveAction = SKEase.move(easeFunction: .curveTypeCubic, easeType: .easeTypeOut, time: 0.3, from: .zero, to: CGPoint(x: 150, y: 150))
        let colorAction = SKEase.createColorTween(.clear,
                                                  end: .systemYellow,
                                                  time: 0.7,
                                                  easingFunction: SKEase.getEaseFunction(.curveTypeElastic, easeType: .easeTypeOut),
                                                  setterBlock: { node, color in
            if let sprite = node as? SKSpriteNode {
                sprite.color = color
            }
        })
        
        static func runAroundTrack() -> SKNode {
            let container = SKNode()
            
            let sprite = SKSpriteNode(color: .systemYellow, size: CGSize(width: 20, height: 60))
            container.addChild(sprite)
            
            let bezierPath = UIBezierPath()
            bezierPath.move(to: CGPoint(x: -115, y: 13))
            bezierPath.addCurve(to: CGPoint(x: -82, y: 91), controlPoint1: CGPoint(x: -154, y: 35), controlPoint2: CGPoint(x: -115, y: 64))
            bezierPath.addCurve(to: CGPoint(x: 2, y: 70), controlPoint1: CGPoint(x: -50, y: 118), controlPoint2: CGPoint(x: -37, y: 67))
            bezierPath.addCurve(to: CGPoint(x: 124, y: 91), controlPoint1: CGPoint(x: 40, y: 74), controlPoint2: CGPoint(x: 105, y: 121))
            bezierPath.addCurve(to: CGPoint(x: 40, y: -82), controlPoint1: CGPoint(x: 144, y: 61), controlPoint2: CGPoint(x: 92, y: -59))
            bezierPath.addCurve(to: CGPoint(x: -115, y: 13), controlPoint1: CGPoint(x: -11, y: -105), controlPoint2: CGPoint(x: -76, y: -10))
            
            let shape = SKShapeNode(path: bezierPath.cgPath)
            shape.name = "shape"
            shape.lineWidth = 30
            shape.strokeColor = .darkGray
            shape.position = .zero
            container.addChild(shape)
            
            sprite.run(SKAction.follow(bezierPath.cgPath, asOffset: false, orientToPath: true, speed: 1500))
            
            return container
        }
        
        static func aNodeThatRotatesBackAndForthThenSettles() -> SKNode {
            let container = SKNode()
            
            let sprite = SKSpriteNode(color: .systemYellow, size: CGSize(width: 4, height: 60))
            container.addChild(sprite)
            
            let action = SKAction.screenRotateWithNode(sprite, angle: 3 * .pi, oscillations: 3, duration: 4)
            sprite.run(SKAction.repeatForever(action))
            
            return container
        }
        
    }
    
    func clone(node: SKNode, grid: CGRect, gap: CGFloat) -> [SKNode] {
        var nodes: [SKNode] = []
        
        let nodeWidth = node.frame.width
        let nodeHeight = node.frame.height
        
        // Calculate how many nodes fit along the x and y axis, considering gaps only between nodes
        let xCount = Int((grid.width + gap) / (nodeWidth + gap))
        let yCount = Int((grid.height + gap) / (nodeHeight + gap))
        
        // Calculate the starting x and y positions to center the grid
        let totalWidth = CGFloat(xCount) * nodeWidth + CGFloat(xCount - 1) * gap
        let totalHeight = CGFloat(yCount) * nodeHeight + CGFloat(yCount - 1) * gap
        
        let startX = grid.midX + nodeWidth/2 - totalWidth/2
        let startY = grid.midY + nodeHeight/2 - totalHeight/2
        
        for i in 0..<(xCount * yCount) {
            let clone = node.copy() as! SKNode
            let xPosition = startX + CGFloat(i % xCount) * (nodeWidth + gap)
            let yPosition = startY + CGFloat(i / xCount) * (nodeHeight + gap)
            //clone.position = CGPoint(x: xPosition, y: yPosition)
            
            let xMove = SKAction.moveTo(x: xPosition, duration: 0.16)
            let yMove = SKAction.moveTo(y: yPosition, duration: 0.16)
            xMove.timingMode = .easeInEaseOut
            yMove.timingMode = .easeInEaseOut
            
            clone.run(SKAction.sequence([
                SKAction.wait(forDuration: 1),
                xMove,
                yMove
            ])) {
                clone.physicsBody = SKPhysicsBody(rectangleOf: clone.frame.size)
                self.setupPhysicsCategories(node: clone, as: .sceneBody)
            }
            
            nodes.append(clone)
        }
        
        return nodes
    }
    
    func doThings(view: SKView, parent: SKNode) {
        
        let rectangle = SKSpriteNode(color: .systemYellow, size: CGSize(width: 30, height: 30))
        
        let grid = CGRect(x: -150, y: -150, width: 300, height: 300)
        let rectangles = clone(node: rectangle, grid: grid, gap: 30)
        
        for rectangle in rectangles {
            parent.addChild(rectangle)
        }
        
    }
    
    func squareMotion(parent: SKNode) {
        let spriteSize = CGSize(width: 60, height: 60)
        let sprite = SKSpriteNode(color: .systemRed, size: spriteSize)
        parent.addChild(sprite)
        
        let right = SKAction.moveBy(x: 200, y: 0, duration: 1)
        right.timingMode = .easeInEaseOut
        let left = SKAction.moveBy(x: -200, y: 0, duration: 1)
        left.timingMode = .easeInEaseOut
        let down = SKAction.moveBy(x: 0, y: -200, duration: 1)
        down.timingMode = .easeInEaseOut
        let up = SKAction.moveBy(x: 0, y: 200, duration: 1)
        up.timingMode = .easeInEaseOut
        
        let sequence = SKAction.sequence([right,down,left,up])
        let moveSequence = SKAction.repeatForever(sequence)
        sprite.run(moveSequence)
    }
    
    // MARK: - Actions With Physics
    
    func actionsWithPhysics(view: SKView, parent: SKNode) {
        let radius: CGFloat = 30
        
        let ball = SKShapeNode(circleOfRadius: radius)
        ball.lineWidth = 0
        ball.fillColor = .systemYellow
        guard let ballTexture = view.texture(from: ball) else { return }
        
        let sprite = DraggableSpriteWithVelocity(texture: ballTexture, color: .systemYellow, size: ballTexture.size())
        sprite.name = "DraggableSpriteWithPhysics"
        sprite.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        setupPhysicsCategories(node: sprite, as: .sceneBody)
        sprite.physicsBody?.restitution = 0.2
        parent.addChild(sprite)
        
        let ground = SKSpriteNode(color: .systemBrown, size: CGSize(width: 390, height: 60))
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        setupPhysicsCategories(node: ground, as: .sceneBody)
        ground.physicsBody?.isDynamic = false
        ground.position.y = -380
        ground.zRotation = 0.5
        parent.addChild(ground)
        
        let ground2 = SKSpriteNode(color: .systemBrown, size: CGSize(width: 390, height: 60))
        ground2.physicsBody = SKPhysicsBody(rectangleOf: ground2.size)
        setupPhysicsCategories(node: ground2, as: .sceneBody)
        ground2.physicsBody?.isDynamic = false
        ground2.position.y = -380
        ground2.zRotation = -0.5
        parent.addChild(ground2)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -11)
        physicsWorld.speed = 1
        let field = SKFieldNode.linearGravityField(withVector: vector_float3(0, 20, 0))
        setupPhysicsCategories(node: field, as: .sceneField)
        //parent.addChild(field)
    }
    
    // MARK: - Update loop
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.update()
            updateZoomLabel()
        }
        
        enumerateChildNodes(withName: "//*DraggableSpriteWithPhysics*", using: { node, _ in
            if let node = node as? DraggableSpriteWithVelocity {
                node.update(currentTime: currentTime)
            }
        })
    }
    
    // MARK: - Touch Began
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
}
