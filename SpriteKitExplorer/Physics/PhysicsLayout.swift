/**
 
 # Physics Layout
 
 A scene to explore building UI using physics.
 
 Achraf Kassioui
 Created: 24 April 2024
 Updated: 30 May 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct PhysicsLayoutView: View {
    @State private var sceneId = UUID()
    var myScene = PhysicsLayoutScene()
    
    var body: some View {
        SpriteView(
            scene: myScene,
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes]
        )
        .id(sceneId)
        .onAppear {
            sceneId = UUID()
        }
        .ignoresSafeArea()
        .background(.black)
    }
}

#Preview {
    PhysicsLayoutView()
}

// MARK: - SpriteKit

class PhysicsLayoutScene: SKScene, PhysicalButtonDelegate, InertialCameraDelegate {
    
    // MARK: - didMove
    
    override func didMove(to view: SKView) {
        /// configure view
        size = view.bounds.size
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
        
        /// filters for testing
        let myFilter = CIFilter.bloom()
        effectLayer.filter = ChainCIFilter(filters: [myFilter])
        effectLayer.shouldEnableEffects = false
        
        /// populate scene
        setupCamera(scale: 1)
        createSceneLayers()
        createPhysicalBoundaryForSceneBodies(size: self.size)
        createPhysicalBoundaryForUIBodies(view: view, UILayer: uiLayer)
        
        createZoomLabel(view: view, parent: uiLayer)
        
        createLeftPaletteWithLinearGravityField(view: view, parent: uiLayer)
        createRightPaletteWithSpringJoint(view: view, parent: uiLayer)
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
        addChild(effectLayer)
        
        objectsLayer.zPosition = 2
        effectLayer.addChild(objectsLayer)
    }
    
    // MARK: - Camera
    
    func resetCamera() {
        if let camera = scene?.camera as? InertialCamera {
            camera.stopInertia()
            camera.setTo(position: .zero, xScale: 1, yScale: 1, rotation: 0)
        }
    }
    
    func setupCamera(scale: CGFloat) {
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.setScale(scale)
        inertialCamera.lockRotation = true
        inertialCamera.lockPan = true
        inertialCamera.delegate = self
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
    
    func createPhysicalBoundaryForSceneBodies(size: CGSize) {
        let physicsBoundaries = CGRect(
            x: -size.width/2,
            y: -size.height/2,
            width: size.width,
            height: size.height
        )
        
        let boundaryForSceneBodies = SKShapeNode(rect: physicsBoundaries)
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
    
    func createSceneConstraints(node: SKNode, insideRect: SKNode) -> SKConstraint {
        let xRange = SKRange(lowerLimit: insideRect.frame.minX + node.frame.size.width / 2,
                             upperLimit: insideRect.frame.maxX - node.frame.size.width / 2)
        let yRange = SKRange(lowerLimit: insideRect.frame.minY + node.frame.size.height / 2,
                             upperLimit: insideRect.frame.maxY - node.frame.size.height / 2)
        
        let constraint = SKConstraint.positionX(xRange, y: yRange)
        constraint.referenceNode = insideRect
        return constraint
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
            newNode.physicsBody?.applyImpulse(CGVector(dx: 0.2, dy: -0.1))
        }
        let waitAction = SKAction.wait(forDuration: interval)
        let sequenceAction = SKAction.sequence([spawnAction, waitAction])
        let repeatAction = SKAction.repeat(sequenceAction, count: count)
        
        parent.run(repeatAction, withKey: "spawnAction")
    }
    
    func createManyObjects() {
        let ball = createBall(radius: 10, color: .systemYellow, name: "ball")
        spawnNodes(
            nodeToSpawn: ball,
            spawnPosition: CGPoint(x: 0, y: 100),
            interval: 0.005,
            count: 50,
            parent: objectsLayer
        )
    }
    
    // MARK: - UI
    
    let buttonSize = CGSize(width: 60, height: 60)
    let theme = ButtonPhysical.Theme.dark
    let _debugColor: SKColor = SKColor(red: 0.49, green: 0.74, blue: 0.74, alpha: 0.2)
    let strokeColor = SKColor(white: 0, alpha: 0.6)
    let fillColor: SKColor = .darkGray
    
    /**
     
     # Palette constructor
     
     */
    func createPalette(size paletteSize: CGSize, radius: CGFloat? = 12, view: SKView) -> SKSpriteNode {
        let bodyExtension: Double = 10
        let cornerRadius = radius ?? 12
        
        /// palette shape
        let paletteShape = SKShapeNode(rectOf: paletteSize, cornerRadius: cornerRadius)
        paletteShape.lineWidth = 2
        paletteShape.strokeColor = strokeColor
        paletteShape.fillColor = fillColor
        
        /// palette
        let paletteSprite = SKSpriteNode(texture: view.texture(from: paletteShape))
        paletteSprite.name = "flickable-palette"
        paletteSprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(
            width: paletteSize.width + bodyExtension,
            height: paletteSize.height + bodyExtension
        ))
        paletteSprite.zPosition = 1
        
        /// palette shadow
        let shadowSprite = SKSpriteNode(
            texture: generateShadowTexture(
                width: paletteSize.width,
                height: paletteSize.height,
                cornerRadius: cornerRadius,
                shadowOffset: CGSize(width: 0, height: 0),
                shadowBlurRadius: 32,
                shadowColor: SKColor(white: 0, alpha: 0.4)
            )
        )
        shadowSprite.zPosition = -1
        shadowSprite.blendMode = .alpha
        paletteSprite.addChild(shadowSprite)
        
        return paletteSprite
    }
    
    // MARK: - UI with fields
    
    func visualizeFieldsWithParticles(view: SKView, parent: SKNode, particleCategory: PhysicsCategory) {
        if let particleEmitter = SKEmitterNode(fileNamed: "VisualizationParticles") {
            particleEmitter.name = "visualization-particles"
            setupPhysicsCategories(node: particleEmitter, as: particleCategory)
            particleEmitter.targetNode = parent
            particleEmitter.zPosition = 0
            particleEmitter.advanceSimulationTime(100)
            parent.addChild(particleEmitter)
        }
    }
    
    func updateSpringFields() {
        enumerateChildNodes(withName: "//*ui-field-spring*", using: {node, _ in
            if let field = node as? SKFieldNode, let camera = self.camera {
                let originalStrength: Float = 40
                let factor = pow(camera.xScale, 2)
                field.strength = originalStrength * Float(factor)
            }
        })
    }
    
    func createLeftPaletteWithElectromagneticField(view: SKView, parent: SKNode) {
        let margin: CGFloat = 20
        let paletteSize = CGSize(width: 60, height: 360)
        
        let electricField = SKFieldNode.electricField()
        electricField.name = "ui-field-electromagnetic"
        setupPhysicsCategories(node: electricField, as: .UIFieldLeft)
        electricField.strength = -5
        electricField.falloff = 0
        electricField.position.x = -view.bounds.width/2 + paletteSize.width/2 + margin
        electricField.position.y = -view.bounds.height/2 + paletteSize.height/2 + margin
        parent.addChild(electricField)
        
        let magneticField = SKFieldNode.magneticField()
        magneticField.name = "ui-field-electromagnetic"
        setupPhysicsCategories(node: magneticField, as: .UIFieldLeft)
        magneticField.strength = -5
        magneticField.falloff = 0
        magneticField.position.x = -view.bounds.width/2 + paletteSize.width/2 + margin
        magneticField.position.y = -view.bounds.height/2 + paletteSize.height/2 + margin
        parent.addChild(magneticField)
        
        let palette: SKSpriteNode = createPalette(size: paletteSize, view: view)
        setupPhysicsCategories(node: palette, as: .UIBodyLeft)
        palette.physicsBody?.linearDamping = 1
        palette.physicsBody?.charge = 1
        palette.constraints = [createConstraintsInView(view: view, node: palette, region: .view, margin: 0)]
        parent.addChild(palette)
        
        let buttonArray: [SKNode] = createLeftButtons(view: view)
        distributeNodes(direction: .vertical, container: palette, nodes: buttonArray)
    }
    
    func createRightPaletteWithRadialGravityField(view: SKView, parent: SKNode) {
        let margin: CGFloat = 10
        let paletteSize = CGSize(width: 60, height: 300)
        
        let field = SKFieldNode.radialGravityField()
        field.name = "ui-field-radial-gravity"
        setupPhysicsCategories(node: field, as: .UIFieldRight)
        field.strength = 40
        field.falloff = -1
        field.minimumRadius = 0
        field.position.x = view.bounds.width/2 - paletteSize.width/2 - margin
        field.position.y = -view.bounds.height/2 + paletteSize.height/2 + margin
        parent.addChild(field)
        
        let palette: SKSpriteNode = createPalette(size: paletteSize, view: view)
        setupPhysicsCategories(node: palette, as: .UIBodyRight)
        palette.physicsBody?.linearDamping = 1
        palette.physicsBody?.restitution = 0.2
        palette.constraints = [createConstraintsInView(view: view, node: palette, region: .view, margin: margin)]
        parent.addChild(palette)
        
        let buttonArray: [SKNode] = createRightButtons(view: view)
        distributeNodes(direction: .vertical, container: palette, nodes: buttonArray)
    }
    
    func createRightPaletteWithLinearGravityField(view: SKView, parent: SKNode) {
        let margin: CGFloat = 10
        let paletteSize = CGSize(width: 60, height: 340)
        
        let field = SKFieldNode.linearGravityField(withVector: vector_float3(40, 0, 0))
        field.name = "ui-field-radial-gravity"
        setupPhysicsCategories(node: field, as: .UIFieldRight)
        field.strength = 1
        field.falloff = 0
        field.position.x = view.bounds.width/2 - paletteSize.width/2 - margin
        field.position.y = -view.bounds.height/2 + paletteSize.height/2 + margin
        parent.addChild(field)
        
        let palette: SKSpriteNode = createPalette(size: paletteSize, view: view)
        setupPhysicsCategories(node: palette, as: .UIBodyRight)
        palette.physicsBody?.linearDamping = 1
        palette.physicsBody?.restitution = 0.01
        palette.constraints = [createConstraintsInView(view: view, node: palette, region: .view, margin: margin)]
        parent.addChild(palette)
        
        let buttonArray: [SKNode] = createRightButtons(view: view)
        distributeNodes(direction: .vertical, container: palette, nodes: buttonArray)
    }
    
    func createLeftPaletteWithLinearGravityField(view: SKView, parent: SKNode) {
        let margin: CGFloat = 10
        let paletteSize = CGSize(width: 60, height: 340)
        
        let field = SKFieldNode.linearGravityField(withVector: vector_float3(-40, 0, 0))
        field.name = "ui-field-radial-gravity"
        setupPhysicsCategories(node: field, as: .UIFieldLeft)
        field.strength = 1
        field.falloff = 0
        field.minimumRadius = 0
        field.position.x = -view.bounds.width/2 + paletteSize.width/2 + margin
        field.position.y = -view.bounds.height/2 + paletteSize.height/2 + margin
        parent.addChild(field)
        
        let palette: SKSpriteNode = createPalette(size: paletteSize, view: view)
        setupPhysicsCategories(node: palette, as: .UIBodyLeft)
        palette.physicsBody?.linearDamping = 1
        palette.physicsBody?.restitution = 0.01
        palette.constraints = [createConstraintsInView(view: view, node: palette, region: .view, margin: margin)]
        parent.addChild(palette)
        
        let buttonArray: [SKNode] = createLeftButtons(view: view)
        distributeNodes(direction: .vertical, container: palette, nodes: buttonArray)
    }
    
    func createLeftPaletteWithSpringField(view: SKView, parent: SKNode) {
        let paletteSize = CGSize(width: 60, height: 360)
        let strength: Float = 10
        let falloff: Float = -2
        let margin: CGFloat = 10
        
        let leftField = SKFieldNode.springField()
        leftField.name = "ui-field-spring"
        setupPhysicsCategories(node: leftField, as: .UIFieldLeft)
        leftField.strength = strength
        leftField.falloff = falloff
        leftField.position.x = -view.bounds.width/2 + paletteSize.width/2 + margin
        leftField.position.y = -view.bounds.height/2 + paletteSize.height/2 + margin
        parent.addChild(leftField)
        
        let palette: SKSpriteNode = createPalette(size: paletteSize, view: view)
        setupPhysicsCategories(node: palette, as: .UIBodyLeft)
        palette.physicsBody?.restitution = 0.2
        palette.constraints = [createConstraintsInView(view: view, node: palette, region: .view, margin: margin)]
        parent.addChild(palette)
        
        let buttonArray: [SKNode] = createLeftButtons(view: view)
        distributeNodes(direction: .vertical, container: palette, nodes: buttonArray)
    }
    
    func createRightPaletteWithSpringField(view: SKView, parent: SKNode) {
        let paletteSize = CGSize(width: 60, height: 360)
        let strength: Float = 40
        let falloff: Float = -2
        let margin: CGFloat = 20
        
        let rightField = SKFieldNode.springField()
        rightField.name = "ui-field-spring"
        setupPhysicsCategories(node: rightField, as: .UIFieldRight)
        rightField.strength = strength
        rightField.falloff = falloff
        rightField.position.x = view.bounds.width/2 - paletteSize.width/2 - margin
        rightField.position.y = -view.bounds.height/2 + paletteSize.height/2 + margin
        parent.addChild(rightField)
        
        let palette: SKSpriteNode = createPalette(size: paletteSize, view: view)
        setupPhysicsCategories(node: palette, as: .UIBodyRight)
        palette.constraints = [createConstraintsInView(view: view, node: palette, region: .view, margin: 0)]
        parent.addChild(palette)
        
        let buttonArray: [SKNode] = createRightButtons(view: view)
        distributeNodes(direction: .vertical, container: palette, nodes: buttonArray)
    }
    
    func createBasePaletteWithField(view: SKView, parent: SKNode) {
        let paletteSize = CGSize(width: 230, height: 60)
        let fieldStrength: Float = 40
        let fieldFalloff: Float = -2
        
        let field = SKFieldNode.springField()
        field.name = "ui-field-spring"
        setupPhysicsCategories(node: field, as: .UIField)
        field.strength = fieldStrength
        field.falloff = fieldFalloff
        field.position.x = 0
        field.position.y = -view.bounds.height/2 + paletteSize.height/2
        parent.addChild(field)
        
        let palette: SKSpriteNode = createPalette(size: paletteSize, view: view)
        setupPhysicsCategories(node: palette, as: .UIBody)
        palette.constraints = [createConstraintsInView(view: view, node: palette, region: .view)]
        parent.addChild(palette)
        
        let buttonArray: [SKNode] = createBaseButtons(view: view)
        distributeNodes(direction: .horizontal, container: palette, nodes: buttonArray)
    }
    
    // MARK: - UI with spring joints
    
    func cameraWillScale(to scale: (x: CGFloat, y: CGFloat)) {
        railNode.physicsBody?.isDynamic = false
        springPalette.physicsBody?.isDynamic = false
        
        springPalette.position = railNode.position
        physicsWorld.remove(UIRightSpringJoint)
    }
    
    func cameraDidScale(to scale: (x: CGFloat, y: CGFloat)) {
        let newAnchorAPosition = convert(railNode.position, from: railNode.parent!)
        let newAnchorBPosition = convert(springPalette.position, from: springPalette.parent!)
        
        self.UIRightSpringJoint = SKPhysicsJointSpring.joint(
            withBodyA: railNode.physicsBody!,
            bodyB: springPalette.physicsBody!,
            anchorA: newAnchorAPosition,
            anchorB: newAnchorBPosition
        )
        //UIRightSpringJoint.frequency = 0
        //UIRightSpringJoint.damping = 0
        physicsWorld.add(self.UIRightSpringJoint)
        
        railNode.physicsBody?.isDynamic = true
        springPalette.physicsBody?.isDynamic = true
    }
    
    func cameraDidMove(to position: CGPoint) {
        
    }
    
    var UIRightSpringJoint = SKPhysicsJointSpring()
    var railNode = SKSpriteNode()
    var springPalette = SKSpriteNode()
    
    func createRightPaletteWithSpringJoint(view: SKView, parent: SKNode) {
        let paletteSize = CGSize(width: 60, height: 340)
        
        railNode = SKSpriteNode(color: .clear, size: paletteSize)
        railNode.name = "flickable"
        railNode.physicsBody = SKPhysicsBody(rectangleOf: railNode.size)
        setupPhysicsCategories(node: railNode, as: .UIBody)
        railNode.constraints = [createConstraintsInView(view: view, node: railNode, region: .rightEdge, margin: 10)]
        railNode.physicsBody?.linearDamping = 4
        railNode.physicsBody?.density = 1
        railNode.position.y = 0
        parent.addChild(railNode)
        
        /// palette shape
        let paletteShape = SKShapeNode(rectOf: paletteSize, cornerRadius: 12)
        paletteShape.lineWidth = 2
        paletteShape.strokeColor = strokeColor
        paletteShape.fillColor = fillColor
        
        /// palette
        springPalette = SKSpriteNode(texture: view.texture(from: paletteShape))
        springPalette.name = "flickable-palette"
        springPalette.physicsBody = SKPhysicsBody(rectangleOf: springPalette.size)
        setupPhysicsCategories(node: springPalette, as: .UIBody)
        springPalette.constraints = [createConstraintsInView(view: view, node: springPalette, region: .view, margin: 10)]
        springPalette.physicsBody?.linearDamping = 4
        springPalette.physicsBody?.density = 1
        springPalette.physicsBody?.allowsRotation = false
        springPalette.physicsBody?.restitution = 0.02
        springPalette.zPosition = 10
        parent.addChild(springPalette)
        
        UIRightSpringJoint = SKPhysicsJointSpring.joint(
            withBodyA: railNode.physicsBody!,
            bodyB: springPalette.physicsBody!,
            anchorA: railNode.position,
            anchorB: springPalette.position
        )
        UIRightSpringJoint.frequency = 0
        UIRightSpringJoint.damping = 0
        physicsWorld.add(UIRightSpringJoint)
        
        /// palette shadow
        let shadowSprite = SKSpriteNode(
            texture: generateShadowTexture(
                width: paletteSize.width,
                height: paletteSize.height,
                cornerRadius: 12,
                shadowOffset: CGSize(width: 0, height: 0),
                shadowBlurRadius: 32,
                shadowColor: SKColor(white: 0, alpha: 0.4)
            )
        )
        shadowSprite.zPosition = -1
        shadowSprite.blendMode = .alpha
        springPalette.addChild(shadowSprite)
        
        /// buttons
        let buttonArray = createRightButtons(view: view)
        distributeNodes(direction: .vertical, container: springPalette, nodes: buttonArray)
    }
    
    // MARK: - UI on rails
    
    func createLeftPaletteWithRails(view: SKView, parent: SKNode) {
        let paletteSize = CGSize(width: 60, height: 320)
        
        let dashedRail = SKShapeNode()
        dashedRail.strokeColor = strokeColor
        dashedRail.lineWidth = 2
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: view.bounds.height/2))
        path.addLine(to: CGPoint(x: 0, y: -view.bounds.height/2))
        dashedRail.path = path.copy(dashingWithPhase: 0, lengths: [4, 8])
        dashedRail.position.x = -view.bounds.width/2 + paletteSize.width/2 + 10
        parent.addChild(dashedRail)
        
        let palette = createPalette(size: paletteSize, view: view)
        setupPhysicsCategories(node: palette, as: .UIBody)
        palette.constraints = [createConstraintsInView(view: view, node: palette, region: .leftEdge, margin: 10)]
        parent.addChild(palette)
        
        let buttonArray = createLeftButtons(view: view)
        distributeNodes(direction: .vertical, container: palette, nodes: buttonArray)
    }
    
    // MARK: - UI Buttons
    
    /**
     A function that implements the PhysicalButtonDelegate protocol for ButtonPhysical
     */
    func buttonTouched(button: ButtonPhysical, touch: UITouch) {
        
    }
    
    func createBaseButtons(view: SKView) -> [SKNode] {
        let debugButton = ButtonPhysical(
            view: view,
            shape: .square,
            size: CGSize(width: 60, height: 60),
            iconInactive: SKTexture(imageNamed: "scope-icon"),
            iconActive: SKTexture(imageNamed: "scope-icon"),
            iconSize: CGSize(width: 32, height: 32),
            theme: theme,
            isPhysical: false,
            onTouch: {
                self.toggleDebugOptions(view: view)
            }
        )
        /// Assign the current scene (self) as delegate for the ButtonPhysicalProtocol
        debugButton.delegate = self
        
        let togglePhysicsButton = ButtonPhysical(
            view: view,
            shape: .square,
            size: CGSize(width: 60, height: 60),
            iconInactive: SKTexture(imageNamed: "gears-icon"),
            iconActive: SKTexture(imageNamed: "gears-slash-icon"),
            iconSize: CGSize(width: 32, height: 32),
            theme: theme,
            isPhysical: false,
            onTouch: {
                self.physicsSimulation.toggle()
            }
        )
        
        let buttonArray = [togglePhysicsButton, debugButton]
        return buttonArray
    }
    
    func createRightButtons(view: SKView) -> [SKNode] {
        let removeButton = ButtonPhysical(
            view: view,
            shape: .square,
            size: buttonSize,
            iconInactive: SKTexture(imageNamed: "trash-icon"),
            iconActive: SKTexture(imageNamed: "trash-icon"),
            iconSize: CGSize(width: 32, height: 32),
            theme: theme,
            isPhysical: false,
            onTouch: {
                self.removeNodes(withName: "ball")
            }
        )
        
        let addButton = ButtonPhysical(
            view: view,
            shape: .square,
            size: buttonSize,
            iconInactive: SKTexture(imageNamed: "plus-icon"),
            iconActive: SKTexture(imageNamed: "plus-icon"),
            iconSize: CGSize(width: 32, height: 32),
            theme: theme,
            isPhysical: false,
            onTouch: {
                let ball = self.createBall(radius: 30, color: .systemYellow, name: "flickable-ball", particleCollider: true)
                self.objectsLayer.addChild(ball)
            }
        )
        
        let AButton = ButtonPhysical(
            view: view,
            shape: .square,
            size: CGSize(width: 60, height: 60),
            iconInactive: SKTexture(imageNamed: "a-icon"),
            iconActive: SKTexture(imageNamed: "a-icon"),
            iconSize: CGSize(width: 32, height: 32),
            theme: theme,
            isPhysical: false,
            onTouch: {
                self.createManyObjects()
            }
        )
        
        let buttonArray = [removeButton, addButton, AButton]
        return buttonArray
    }
    
    func createLeftButtons(view: SKView) -> [SKNode] {
        let gravityButton = ButtonPhysical(
            view: view,
            shape: .square,
            size: buttonSize,
            iconInactive: SKTexture(imageNamed: "gravity-off-icon"),
            iconActive: SKTexture(imageNamed: "gravity-icon"),
            iconSize: CGSize(width: 32, height: 32),
            theme: theme,
            isPhysical: false,
            onTouch: {
                self.sceneGravity.toggle()
            }
        )
        
        let resetCameraButton = ButtonPhysical(
            view: view,
            shape: .square,
            size: buttonSize,
            iconInactive: SKTexture(imageNamed: "camera-reset-icon"),
            iconActive: SKTexture(imageNamed: "camera-reset-icon"),
            iconSize: CGSize(width: 60, height: 60),
            theme: theme,
            isPhysical: false,
            onTouch: {
                self.resetCamera()
            }
        )
        
        let toggleCameraControlButton = ButtonPhysical(
            view: view,
            shape: .square,
            size: CGSize(width: 60, height: 60),
            iconInactive: SKTexture(imageNamed: "camera-unlock-icon"),
            iconActive: SKTexture(imageNamed: "camera-lock-icon"),
            iconSize: CGSize(width: 32, height: 32),
            theme: theme,
            isPhysical: false,
            onTouch: {
                if let camera = self.camera as? InertialCamera {
                    camera.lock.toggle()
                }
            }
        )
        
        let debugButton = ButtonPhysical(
            view: view,
            shape: .square,
            size: CGSize(width: 60, height: 60),
            iconInactive: SKTexture(imageNamed: "chart-bar-icon"),
            iconActive: SKTexture(imageNamed: "chart-bar-icon"),
            iconSize: CGSize(width: 32, height: 32),
            theme: theme,
            isPhysical: false,
            onTouch: {
                self.toggleDebugOptions(view: view)
            }
        )
        
        let buttonArray = [gravityButton, resetCameraButton, toggleCameraControlButton, debugButton]
        return buttonArray
    }
    
    // MARK: - Update
    
    private var touchPreviousDistance: CGFloat = 0
    
    override func update(_ currentTime: TimeInterval) {
        /// UI Field update
        updateSpringFields()
        
        /// Display camera zoom
        updateZoomLabel()
        
        /// camera inertia
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.update()
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
    
    // MARK: - didSimulate
    
    override func didSimulatePhysics() {
        
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
                        body.density = 10000
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
