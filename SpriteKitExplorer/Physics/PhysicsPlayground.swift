/**
 
 # SpriteKit Physics Playground
 
 Achraf Kassioui
 Created: 2 May 2024
 Updated: 3 May 2024
 
 */
import SwiftUI
import SpriteKit
import CoreImage.CIFilterBuiltins

// MARK: SwiftUI

struct PhysicsPlaygroundView: View {
    @State private var sceneId = UUID()
    @State var isPaused = false
    var scene = PhysicsPlaygroundScene()
    @State var spriteViewSize: CGSize = .zero
    
    var body: some View {
        VStack (spacing: 0) {
            GeometryReader { geometryProxy in
                let proxy = geometryProxy
                SpriteView(
                    scene: scene,
                    options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes]
                )
                .ignoresSafeArea()
                .onChange(of: proxy.size) {
                    print(proxy.size)
                }
            }
            
            VStack {
                menuBar()
            }
        }
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
        .background(.black)
    }
    
    private func menuBar() -> some View {
        HStack {
            Spacer()
            createObjectsButton
            playPauseButton
            debugButton
            Spacer()
        }
        .padding([.top, .leading, .trailing], 10)
        .background(.ultraThinMaterial)
        .shadow(radius: 10)
    }
    
    private var createObjectsButton: some View {
        Button(action: {
            scene.createManyObjects()
        }) {
            Image("plus-icon").colorInvert()
        }
        .buttonStyle(roundButtonStyle())
    }
    
    private var playPauseButton: some View {
        Button(action: {
            isPaused.toggle()
            scene.pauseScene(isPaused)
        }) {
            Image(systemName: isPaused ? "play.fill" : "pause.fill")
        }
        .buttonStyle(roundButtonStyle())
    }
    
    private var debugButton: some View {
        Button(action: {
            if let view = scene.view {
                scene.toggleDebugOptions(view: view)
            }
        }, label: {
            Image("chart-bar-icon").colorInvert()
        })
        .buttonStyle(roundButtonStyle())
    }
}

#Preview {
    PhysicsPlaygroundView()
}

// MARK: SpriteKit

class PhysicsPlaygroundScene: SKScene, InertialCameraDelegate {

    // MARK: - didMove
    
    override func didMove(to view: SKView) {
        /// configure view
        size = CGSize(width: 390, height: 693)
        //size = view.bounds.size
        scaleMode = .resizeFill
        view.contentMode = .center
        backgroundColor = SKColor(red: 0.89, green: 0.89, blue: 0.84, alpha: 1)
        backgroundColor = .gray
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        view.isMultipleTouchEnabled = true
        
        cleanPhysics()
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        /// create background
        let gridTexture = generateGridTexture(cellSize: 150, rows: 10, cols: 10, linesColor: SKColor(white: 0, alpha: 0.6))
        let gridbackground = SKSpriteNode(texture: gridTexture)
        gridbackground.zPosition = -1
        objectsLayer.addChild(gridbackground)
        
        /// camera
        setupCamera()
        
        /// filters for testing
        let myFilter = CIFilter.motionBlur()
        filter = ChainCIFilter(filters: [myFilter])
        shouldEnableEffects = false
        
        /// populate scene
        createSceneLayers()
        createPhysicalBoundaryForSceneBodies(size: self.size)
        createPhysicalBoundaryForUIBodies(view: view, UILayer: uiLayer)
        
        createZoomLabel(view: view, parent: uiLayer)
        updateZoomLabel()
        
        /// This applies a random shaking motion to the camera
        createNoiseField(parent: uiLayer)
    }
    
    // MARK: - Global Variables
    
    var sceneGravity = false {
        didSet {
            if sceneGravity { self.physicsWorld.gravity = CGVector(dx: 0, dy: -20) }
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
        if let camera = scene?.camera {
            uiLayer.zPosition = 9999
            camera.addChild(uiLayer)
        } else {
            print("There is no camera in scene. UILayer is not visible.")
        }
        
        effectLayer.zPosition = 1
        effectLayer.shouldEnableEffects = false
        addChild(effectLayer)
        
        objectsLayer.zPosition = 2
        effectLayer.addChild(objectsLayer)
    }
    
    // MARK: - Camera
    
    func cameraWillScale(to scale: (x: CGFloat, y: CGFloat)) {        
        updateUIFields(scale: scale.x)
    }
    
    func cameraDidScale(to scale: (x: CGFloat, y: CGFloat)) {
        
    }
    
    func cameraDidMove(to position: CGPoint) {
        
    }
    
    func resetCamera() {
        if let camera = scene?.camera as? InertialCamera {
            camera.stopInertia()
            camera.setTo(position: .zero, xScale: 1, yScale: 1, rotation: 0)
        }
    }
    
    func setupCamera() {
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.delegate = self
        inertialCamera.lockRotation = true
        inertialCamera.physicsBody = SKPhysicsBody(circleOfRadius: 30)
        setupPhysicsCategories(node: inertialCamera, as: .UIBody)
        camera = inertialCamera
        addChild(inertialCamera)
    }
    
    func createZoomLabel(view: SKView, parent: SKNode) {
        zoomLabel.fontName = "SF-Pro"
        zoomLabel.fontSize = 16
        zoomLabel.fontColor = .white
        zoomLabel.horizontalAlignmentMode = .center
        zoomLabel.verticalAlignmentMode = .center
        zoomLabel.position.y = view.bounds.height/2 - zoomLabel.calculateAccumulatedFrame().height/2 - view.safeAreaInsets.top - 20
        parent.addChild(zoomLabel)
    }
    
    func updateZoomLabel() {
        guard let camera = camera else { return }
        let zoomPercentage = 100 / (camera.xScale)
        zoomLabel.text = String(format: "Zoom: %.0f%%", zoomPercentage)
    }
    
    // MARK: - Physics and constraints
    
    var boundaryForSceneBodies = SKShapeNode()
    
    func createPhysicalBoundaryForSceneBodies(size: CGSize) {
        let physicsBoundaries = CGRect(
            x: -size.width/2,
            y: -size.height/2,
            width: size.width,
            height: size.height
        )
        
        boundaryForSceneBodies = SKShapeNode(rect: physicsBoundaries)
        boundaryForSceneBodies.lineWidth = 1
        boundaryForSceneBodies.strokeColor = SKColor(white: 0, alpha: 0.3)
        boundaryForSceneBodies.physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBoundaries)
        setupPhysicsCategories(node: boundaryForSceneBodies, as: .sceneBoundary)
        boundaryForSceneBodies.zPosition = -1
        addChild(boundaryForSceneBodies)
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
    
    // MARK: - Fields
    
    func updateUIFields(scale: CGFloat) {
        enumerateChildNodes(withName: "//*UIField*", using: { node, _ in
            if let field = node as? SKFieldNode {
                let factor = 1 / Float(scale)
                let originalStrength: Float = 1
                field.strength = originalStrength * factor
            }
        })
    }
    
    func createNoiseField(parent: SKNode) {
        let field = SKFieldNode.noiseField(withSmoothness: 0, animationSpeed: 1)
        field.name = "UIField"
        setupPhysicsCategories(node: field, as: .UIField)
        field.strength = 1
        parent.addChild(field)
    }
    
    /// Emergent behavior with spawned rectangles of size 30x30
    func createLorenzSystem(parent: SKNode) {
        let magField1 = SKFieldNode.magneticField()
        magField1.strength = -10
        setupPhysicsCategories(node: magField1, as: .sceneField)
        magField1.position = CGPoint(x: -100, y: 100)
        parent.addChild(magField1)
    }
    
    // MARK: - Scene Objects
    
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
            /// This line is necessary to create the emergent behavior with a magnetic field
            newNode.physicsBody?.applyImpulse(CGVector(dx: 0.2, dy: -0.1))
        }
        let waitAction = SKAction.wait(forDuration: interval)
        let sequenceAction = SKAction.sequence([spawnAction, waitAction])
        let repeatAction = SKAction.repeat(sequenceAction, count: count)
        
        parent.run(repeatAction, withKey: "spawnAction")
    }
    
    func createManyObjects() {
        let rectangle = createRoundedRectangle(
            size: CGSize(width: 30, height: 30),
            color: .systemYellow,
            name: "ball-flickable",
            constrainInside: boundaryForSceneBodies
        )
        spawnNodes(
            nodeToSpawn: rectangle,
            spawnPosition: CGPoint(x: 0, y: 100),
            interval: 0.005,
            count: 50,
            parent: objectsLayer
        )
    }
    
    // MARK: - Update loop
    
    private var touchPreviousDistance: CGFloat = 0
    
    override func update(_ currentTime: TimeInterval) {
        
        /// camera inertia
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.update()
            updateZoomLabel()
        }
        
        /// dragging with physics
        if !velocityNodes.isEmpty {
            velocityNodes.forEach { touch, node in
                let currentPos = touch.location(in: self)
                let previousPos = touch.previousLocation(in: self)
                let distance = CGVector(
                    dx: currentPos.x - previousPos.x,
                    dy: currentPos.y - previousPos.y
                ).length()
                
                if distance == touchPreviousDistance {
                    node.physicsBody?.velocity = .zero
                    node.physicsBody?.angularVelocity = 0
                }
                
                touchPreviousDistance = distance
            }
        }
    }
    
    // MARK: Visualization
    
    /**
     
     Update the shape nodes to visualize interaction
     
     */
    func updateDraggingVisualization() {
        if !draggingVisualization.isEmpty {
            draggingVisualization.forEach { touch, line in
                if let selectedNode = velocityNodes[touch], let line = draggingVisualization[touch] {
                    /// calculate the minimum radius based on half the larger side of the node's frame
                    let nodeFrame = selectedNode.calculateAccumulatedFrame()
                    let minRadius = max(nodeFrame.width, nodeFrame.height) / 2
                    
                    /// calculate the radius required to include the touch location
                    let touchDistance = (selectedNode.position - touch.location(in: self)).length()
                    let maxRadius = max(minRadius, touchDistance)
                    
                    /// create the circle's rectangle based on the calculated radius
                    let circleRect = CGRect(x: selectedNode.position.x - maxRadius, y: selectedNode.position.y - maxRadius, width: maxRadius * 2, height: maxRadius * 2)
                    let path = UIBezierPath(ovalIn: circleRect)
                    line.path = path.cgPath
                }
            }
        }
    }
    
    func firstBlockInTouchesBegan(touch: UITouch, touchedNode: SKNode) {
        let location = touch.location(in: self)
        
        /// create a line shape node to visualize interaction
        let line = SKShapeNode(circleOfRadius: 0)
        line.lineWidth = 3
        line.strokeColor = SKColor(white: 1, alpha: 0.6)
        line.zPosition = 1000
        addChild(line)
        draggingVisualization[touch] = line
        
        /// update the line's initial position to connect the node and touch location
        if let line = draggingVisualization[touch] {
            let radius = abs((touchedNode.position - location).length())
            let circleRect = CGRect(x: touchedNode.position.x - radius, y: touchedNode.position.y - radius, width: radius * 2, height: radius * 2)
            let path = UIBezierPath(ovalIn: circleRect)
            line.path = path.cgPath
        }
    }
    
    func secondBlockInTouchesBegan(touch: UITouch) {
        let location = touch.location(in: self)
        
        if let node = velocityNodes[touch], let line = draggingVisualization[touch] {
            let path = UIBezierPath()
            path.move(to: node.position)
            path.addLine(to: location)
            line.path = path.cgPath
        } else if let node = velocityNodes[touch] {
            let path = UIBezierPath()
            path.move(to: node.position)
            path.addLine(to: location)
            let line = SKShapeNode(path: path.cgPath)
            line.strokeColor = .white
            addChild(line)
            draggingVisualization[touch] = line
        }
    }
    
    /**
     
     Draws a line between a pair of anchor-A and anchor-B nodes, using an existing node named joint-link.
     
     */
    func visualizeOnePairOfJointAnchors() {
        self.enumerateChildNodes(withName: "//*anchor-A") { jointStart, _ in
            self.enumerateChildNodes(withName: "//*anchor-B") { jointEnd, _ in
                if let jointLink = self.childNode(withName: "//*joint-link*") as? SKShapeNode {
                    let path = CGMutablePath()
                    path.move(to: jointStart.position)
                    path.addLine(to: jointEnd.position)
                    jointLink.path = path
                    
                    if jointLink.name?.contains("dashed") ?? false {
                        let dashes: [CGFloat] = [4, 10]
                        let phase: CGFloat = 0
                        let dashedPath = path.copy(dashingWithPhase: phase, lengths: dashes)
                        jointLink.path = dashedPath
                    }
                }
            }
        }
    }
    
    // MARK: - didSimulate
    
    override func didSimulatePhysics() {
        
        self.enumerateChildNodes(withName: "//*anchor-A*", using: { anchor, _ in
            guard let connectedJoints = anchor.physicsBody?.joints else { return }
            for _ in connectedJoints {
                
            }
        })
        
        visualizeOnePairOfJointAnchors()
        
        //clampVelocity()
    }
    
    // MARK: - Touch
    
    /// dragging with physics
    enum PhysicsProperties {
        case density
        case affectedByGravity
        case collisionBitMask
        case fieldBitMask
    }
    private var velocityNodes: [UITouch: SKNode] = [:]
    private var velocityOffsets: [UITouch: CGPoint] = [:]
    private var velocityNodesOriginalStates: [UITouch: [PhysicsProperties: Any]] = [:]
    private var touchPreviousTimestamp: [UITouch: TimeInterval] = [:]
    private var draggingVisualization: [UITouch: SKShapeNode] = [:]
    
    /// dragging with verlet integration
    private var verletNodes: [UITouch: SKNode] = [:]
    private var verletPreviousPositions: [UITouch: CGPoint] = [:]
    private var verletTouchPreviousTimestamp: [UITouch: TimeInterval] = [:]
    
    /// dragging with position
    private var positionNodes: [UITouch: SKNode] = [:]
    private var touchOffsets: [UITouch: CGPoint] = [:]
    private var originalDynamicStates: [UITouch: Bool] = [:]
    
    /// debug fields
    func sampleFields(point: CGPoint) {
        let positionVector = vector_float3(Float(point.x), Float(point.y), 0)
        let force = physicsWorld.sampleFields(at: positionVector)
        print(force)
    }
    
    // MARK: Touches Began
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = atPoint(location)
            
            /// dragging with physics --------------------------------------------------------------
            if touchedNode.name?.contains("flickable") ?? false {
                guard let body = touchedNode.physicsBody else {
                    print("Touched node has no physical body")
                    return
                }
                
                if let inertialCamera = scene?.camera as? InertialCamera {
                    inertialCamera.lock = true
                }

                velocityNodes[touch] = touchedNode
                
                velocityNodesOriginalStates[touch] = [
                    .density : body.density,
                    .affectedByGravity: body.affectedByGravity,
                    .collisionBitMask: body.collisionBitMask,
                    .fieldBitMask: body.fieldBitMask
                ]
                
                if let camera = camera, touchedNode.inParentHierarchy(camera) {
                    let locationInCamera = convert(location, to: camera)
                    velocityOffsets[touch] = locationInCamera - touchedNode.position
                    
                    if (touchedNode.physicsBody?.joints) != nil {
                        //body.density = 100000
                    }
                    
                } else {
                    velocityOffsets[touch] = location - touchedNode.position
                }
                
                //body.density *= 10000
                body.affectedByGravity = false
                body.collisionBitMask = 0
                //body.fieldBitMask = 0
                
                body.velocity = .zero
                body.angularVelocity = .zero
                
                // first visualization block goes here
            }
            
            // second visualization block goes here
            
            /// verlet integration --------------------------------------------------------------
            if touchedNode.name?.contains("verlet") ?? false {
                touchOffsets[touch] = location - touchedNode.position
                verletNodes[touch] = touchedNode
                verletPreviousPositions[touch] = location
            }
            
            /// dragging with position --------------------------------------------------------------
            if touchedNode.name?.contains("draggable") ?? false {
                if let camera = camera, let _ = touchedNode.parent as? SKCameraNode {
                    let locationInCamera = convert(location, to: camera)
                    touchOffsets[touch] = locationInCamera - touchedNode.position
                } else {
                    touchOffsets[touch] = location - touchedNode.position
                }
                positionNodes[touch] = touchedNode
                originalDynamicStates[touch] = touchedNode.physicsBody?.isDynamic ?? false
                touchedNode.physicsBody?.isDynamic = false
            }
            
            /// camera logic --------------------------------------------------------------
            if let inertialCamera = camera as? InertialCamera {
                inertialCamera.stopInertia()
            }
        }
    }
    
    // MARK: Touches Moved
    func exponentialScaleFactor(for input: CGFloat) -> CGFloat {
        let base: CGFloat = 10
        let exponent: CGFloat = log10(input)
        return pow(base, exponent)
    }
    
    func logarithmicScaleFactor(for input: CGFloat) -> CGFloat {
        let factor = log10(input + 1) * 10 // Adjust constants as needed
        return max(0.1, factor)
    }
    
    func polynomialScaleFactor(for input: CGFloat) -> CGFloat {
        return pow(input, 0.25) // Adjust exponent as needed
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            /// dragging with physics --------------------------------------------------------------
            if let node = velocityNodes[touch], let offset = velocityOffsets[touch], let body = node.physicsBody {
                if let camera = camera, node.inParentHierarchy(camera) {
                    
                    let locationInCamera = convert(location, to: camera)
                    
                    if self.physicsWorld.speed == 0 {
                        node.position = locationInCamera - offset
                    } else {
                        let dx = location.x - touch.previousLocation(in: self).x
                        let dy = location.y - touch.previousLocation(in: self).y
                        
                        let scaleFactor = pow(camera.yScale, 0)
                        
                        let dt = touch.timestamp - (touchPreviousTimestamp[touch] ?? 0)
                        let velocity = CGVector(dx: (dx * scaleFactor)/dt, dy: (dy * scaleFactor)/dt)
                        
                        body.velocity = velocity
                        
                        touchPreviousTimestamp[touch] = touch.timestamp
                    }
                    
                } else {
                    
                    if self.physicsWorld.speed == 0 {
                        node.position = location - offset
                    } else {
                        let dx = location.x - touch.previousLocation(in: self).x
                        let dy = location.y - touch.previousLocation(in: self).y
                        let dt = touch.timestamp - (touchPreviousTimestamp[touch] ?? 0)
                        let velocity = CGVector(dx: dx/dt, dy: dy/dt)
                        body.velocity = velocity
                        touchPreviousTimestamp[touch] = touch.timestamp
                    }
                    
                }
            }
            
            /// verlet integration --------------------------------------------------------------
            if let verletNode = verletNodes[touch] {
                
                let currentLocation = location
                let previousLocation = verletPreviousPositions[touch] ?? currentLocation
                let dt = touch.timestamp - (verletTouchPreviousTimestamp[touch] ?? touch.timestamp)
                
                // Calculate acceleration (in this case, just using gravity)
                let acceleration = CGVector(dx: 0, dy: -9.8) // Replace with actual acceleration if any
                
                // Convert dt to seconds
                let dtSquared = CGFloat(dt * dt)
                
                // Verlet integration
                let newLocation = CGPoint(
                    x: 2 * currentLocation.x - previousLocation.x + acceleration.dx * dtSquared,
                    y: 2 * currentLocation.y - previousLocation.y + acceleration.dy * dtSquared
                )
                
                // Update node position
                verletNode.position = newLocation
                
                // Update the stored previous position
                verletPreviousPositions[touch] = currentLocation
                
                // Update touch timestamp
                verletTouchPreviousTimestamp[touch] = touch.timestamp
            }
            
            /// dragging with position --------------------------------------------------------------
            if let selectedNode = positionNodes[touch], let offset = touchOffsets[touch] {
                if let camera = camera, let _ = selectedNode.parent as? SKCameraNode {
                    let locationInCamera = convert(location, to: camera)
                    selectedNode.position = locationInCamera - offset
                } else {
                    selectedNode.position = location - offset
                }
            }
        }
    }
    
    // MARK: Touches Ended
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            
            /// dragging with physics --------------------------------------------------------------
            
            if let node = velocityNodes.removeValue(forKey: touch), let originalState = velocityNodesOriginalStates.removeValue(forKey: touch) {
                
                //let adjustedDensity: CGFloat
                
                // Adjust density using an exponential relationship
                //let cameraScale = camera!.xScale
                //let base: CGFloat = 100
                //adjustedDensity = pow(base, -cameraScale)
                
                // Ensure the density doesn't become too extreme
                //let minDensity: CGFloat = 0.0001
                //let maxDensity: CGFloat = 10000
                //let clampedDensity = max(minDensity, min(maxDensity, adjustedDensity))
                
                //node.physicsBody?.density = clampedDensity
                //print("density on release: \(String(describing: node.physicsBody?.density))")
                
                node.physicsBody?.density = originalState[.density] as? CGFloat ?? 1
                node.physicsBody?.affectedByGravity = originalState[.affectedByGravity] as? Bool ?? false
                node.physicsBody?.collisionBitMask = originalState[.collisionBitMask] as? UInt32 ?? 0xFFFFFFFF
                node.physicsBody?.fieldBitMask = originalState[.fieldBitMask] as? UInt32 ?? 0xFFFFFFFF
            }
            velocityOffsets[touch] = nil
            touchPreviousTimestamp[touch] = nil
            
            if let arrow = draggingVisualization.removeValue(forKey: touch) {
                arrow.removeFromParent()
            }
            
            if velocityNodes.isEmpty {
                if let inertialCamera = scene?.camera as? InertialCamera {
                    inertialCamera.lock = false
                }
            }
            
            /// verlet integration --------------------------------------------------------------
            verletNodes[touch] = nil
            verletPreviousPositions.removeValue(forKey: touch)
            verletTouchPreviousTimestamp.removeValue(forKey: touch)
            
            /// dragging with position --------------------------------------------------------------
            if let node = positionNodes.removeValue(forKey: touch),
               let originalDynamicState = originalDynamicStates.removeValue(forKey: touch) {
                node.physicsBody?.isDynamic = originalDynamicState
            }
            touchOffsets[touch] = nil
            positionNodes[touch] = nil
            originalDynamicStates[touch] = nil
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
