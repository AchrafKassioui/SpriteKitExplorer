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
    @State var isMinimized = false
    var scene = PhysicsPlaygroundScene()
    
    var body: some View {
        VStack (spacing: 0) {
            GeometryReader { geo in
                SpriteView(
                    scene: scene,
                    options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes]
                )
                .onAppear {
                    scene.sceneSize = geo.size
                }
                .onChange(of: geo.size) {
                    scene.sceneSize = geo.size
                }
            }
            /// force recreation using the unique ID
            .id(sceneId)
            .onAppear {
                /// generate a new ID on each appearance
                sceneId = UUID()
            }
            //.ignoresSafeArea(.all, edges: [.trailing, .leading])
            .ignoresSafeArea()
            
            VStack {
                //menuBar()
            }
        }
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
        .background(.black)
    }
    
    private func menuBar() -> some View {
        HStack {
            Spacer()
            zoomOutButton
            zoomInButton
            playPauseButton
            debugButton
            minimizeButton
            Spacer()
        }
        .frame(height: isMinimized ? nil : 280)
        .padding([.top, .leading, .trailing], 10)
        .background(.ultraThinMaterial)
        .shadow(radius: 10)
    }
    
    private var zoomOutButton: some View {
        Button(action: {
            scene.cameraZoomBy(factor: 0.25)
        }) {
            Image("zoom-out-icon").colorInvert()
        }
        .buttonStyle(roundButtonStyle())
    }
    
    private var zoomInButton: some View {
        Button(action: {
            scene.cameraZoomBy(factor: -0.1)
        }) {
            Image("zoom-in-icon").colorInvert()
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
    
    private var minimizeButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isMinimized.toggle()
            }
        }, label: {
            Image(isMinimized ? "chevron-up-icon" : "chevron-down-icon")
                .colorInvert()
        })
        .buttonStyle(roundButtonStyle())
    }
}

#Preview {
    PhysicsPlaygroundView()
}

// MARK: SpriteKit

class PhysicsPlaygroundScene: SKScene, PhysicalButtonDelegate {

    // MARK: - didMove
    
    override func didMove(to view: SKView) {
        /// configure view
        size = sceneSize
        scaleMode = .resizeFill
        view.contentMode = .center
        backgroundColor = SKColor(red: 0.89, green: 0.89, blue: 0.84, alpha: 1)
        backgroundColor = .gray
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        view.isMultipleTouchEnabled = true
        
        cleanPhysics()
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        /// create background
        let gridTexture = generateGridTexture(cellSize: 150/4, rows: 22, cols: 11, linesColor: SKColor(white: 0, alpha: 0.1))
        let gridbackground = SKSpriteNode(texture: gridTexture)
        gridbackground.zPosition = -1
        objectsLayer.addChild(gridbackground)
        
        /// camera
        setupCamera(zoom: 1)
        
        /// filters for testing
        let myFilter = CIFilter.bloom()
        effectLayer.filter = ChainCIFilter(filters: [myFilter])
        effectLayer.shouldEnableEffects = false
        
        /// populate scene
        createSceneLayers()
        createPhysicalBoundaryForSceneBodies(size: self.size)
        createPhysicalBoundaryForUIBodies(view: view, UILayer: uiLayer)
        
        createZoomDisplay(view: view, parent: uiLayer)
        updateZoomLabel()

        //createLeftPaletteWithSpringField(view: view, parent: uiLayer)
        //createRightPaletteWithRadialGravityField(view: view, parent: uiLayer)
        
        createBottomDrawer(view: view, parent: uiLayer)
        
        //createLorenzSystem(parent: objectsLayer)
        //visualizeFieldsWithParticles(view: view, parent: objectsLayer, particleCategory: .sceneParticle)
    }
    
    func createLorenzSystem(parent: SKNode) {
        let magField1 = SKFieldNode.magneticField()
        magField1.strength = -1
        setupPhysicsCategories(node: magField1, as: .sceneField)
        magField1.position = CGPoint(x: -100, y: 100)
        parent.addChild(magField1)
        
        let magField2 = SKFieldNode.magneticField()
        magField2.strength = 0.01
        setupPhysicsCategories(node: magField2, as: .sceneField)
        magField1.position = CGPoint(x: 100, y: 100)
        //parent.addChild(magField2)
        
        let magField3 = SKFieldNode.magneticField()
        setupPhysicsCategories(node: magField3, as: .sceneField)
        magField1.position = CGPoint(x: 100, y: -100)
        //parent.addChild(magField3)
        
        let magField4 = SKFieldNode.magneticField()
        setupPhysicsCategories(node: magField4, as: .sceneField)
        magField1.position = CGPoint(x: -100, y: -100)
        //parent.addChild(magField4)
    }
    
    // MARK: - Global Variables
    
    var sceneSize: CGSize = .zero {
        didSet {
            self.size = sceneSize
            print(sceneSize)
        }
    }
    
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
    var zoomLabel = SKLabelNode()
    let effectLayer = SKEffectNode()
    let objectsLayer = SKNode()
    
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
    
    func cameraZoomBy(factor: CGFloat) {
        if let camera = self.camera {
            camera.xScale += factor
            camera.yScale += factor
        }
    }
    
    func resetCamera() {
        if let camera = scene?.camera as? InertialCamera {
            camera.stopInertia()
            camera.setTo(position: .zero, xScale: 1, yScale: 1, rotation: 0)
        }
    }
    
    func setupCamera(zoom: CGFloat) {
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.name = "camera"
        inertialCamera.maxScale = 10
        inertialCamera.minScale = 0.25
        inertialCamera.setScale(zoom)
        inertialCamera.lockRotation = true
        camera = inertialCamera
        addChild(inertialCamera)
    }
    
    func createZoomDisplay(view: SKView, parent: SKNode) {
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
    
    func createSceneConstraints(node: SKNode, insideRect: SKNode) -> SKConstraint {
        let xRange = SKRange(lowerLimit: insideRect.frame.minX + node.frame.size.width / 2,
                             upperLimit: insideRect.frame.maxX - node.frame.size.width / 2)
        let yRange = SKRange(lowerLimit: insideRect.frame.minY + node.frame.size.height / 2,
                             upperLimit: insideRect.frame.maxY - node.frame.size.height / 2)
        
        let constraint = SKConstraint.positionX(xRange, y: yRange)
        constraint.referenceNode = insideRect
        return constraint
    }
    
    // MARK: - UI
    
    let buttonSize = CGSize(width: 60, height: 60)
    let theme = ButtonPhysical.Theme.dark
    let _debugColor: SKColor = SKColor(red: 0.49, green: 0.74, blue: 0.74, alpha: 0.2)
    let strokeColor = SKColor(white: 0, alpha: 0.6)
    let fillColor: SKColor = .darkGray
    
    /**
     A function that implements the PhysicalButtonDelegate protocol for ButtonPhysical
     */
    func buttonTouched(button: ButtonPhysical, touch: UITouch) {
        
    }
    
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
    
    // MARK: - UI Drawer
    
    func createBottomDrawer(view: SKView, parent: SKNode) {
        let drawerSize = CGSize(width: view.bounds.width, height: 120)
        
        let drawer = createPalette(size: drawerSize, radius: 0, view: view)
        setupPhysicsCategories(node: drawer, as: .UIBody)
        drawer.physicsBody?.isDynamic = false
        drawer.position.y = -view.bounds.height/2 + drawerSize.height/2
        parent.addChild(drawer)
        
        let buttonArray = createLeftButtons(view: view)
        distributeNodes(direction: .horizontal, container: drawer, nodes: buttonArray)
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
        let paletteSize = CGSize(width: 60, height: 200)
        
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
    
    func createLeftPaletteWithLinearGravityField(view: SKView, parent: SKNode) {
        let margin: CGFloat = 10
        let paletteSize = CGSize(width: 60, height: 360)
        
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
        palette.physicsBody?.restitution = 0.2
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

    func createRightFieldPalette(view: SKView, parent: SKNode) {
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

    var UIleftSpringJoint = SKPhysicsJointSpring()
    
    func createRightPaletteWithSpringJoint(view: SKView, parent: SKNode) {
        let paletteSize = CGSize(width: 60, height: 240)
        
        let railNode = SKSpriteNode(color: .clear, size: paletteSize)
        railNode.name = "flickable"
        railNode.physicsBody = SKPhysicsBody(rectangleOf: railNode.size)
        setupPhysicsCategories(node: railNode, as: .UIBody)
        railNode.physicsBody?.linearDamping = 4
        railNode.constraints = [createConstraintsInView(view: view, node: railNode, region: .rightEdge, margin: 10)]
        railNode.position.y = 0
        //railNode.zPosition = 100
        parent.addChild(railNode)
        
        /// palette shape
        let paletteShape = SKShapeNode(rectOf: paletteSize, cornerRadius: 12)
        paletteShape.lineWidth = 2
        paletteShape.strokeColor = strokeColor
        paletteShape.fillColor = fillColor
        
        /// palette
        let palette = SKSpriteNode(texture: view.texture(from: paletteShape))
        palette.name = "flickable-palette"
        palette.physicsBody = SKPhysicsBody(rectangleOf: palette.size)
        setupPhysicsCategories(node: palette, as: .UIBody)
        palette.constraints = [createConstraintsInView(view: view, node: palette, region: .view, margin: 10)]
        palette.physicsBody?.linearDamping = 1
        palette.physicsBody?.allowsRotation = false
        palette.physicsBody?.restitution = 0.02
        palette.zPosition = 10
        parent.addChild(palette)
        
        UIleftSpringJoint = SKPhysicsJointSpring.joint(
            withBodyA: railNode.physicsBody!,
            bodyB: palette.physicsBody!,
            anchorA: railNode.position,
            anchorB: palette.position
        )
        UIleftSpringJoint.frequency = 0
        UIleftSpringJoint.damping = 2
        physicsWorld.add(UIleftSpringJoint)
        
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
        palette.addChild(shadowSprite)
        
        /// buttons
        let buttonArray = createRightButtons(view: view)
        distributeNodes(direction: .vertical, container: palette, nodes: buttonArray)
    }
    
    // MARK: - UI with rails

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
        
        let buttonArray = [removeButton, addButton]
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
        gravityButton.delegate = self
        
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
                print("This button does nothing")
            }
        )
        
        let buttonArray = [gravityButton, resetCameraButton, toggleCameraControlButton, AButton]
        return buttonArray
    }
    
    // MARK: - Update loop
    
    private var touchPreviousDistance: CGFloat = 0
    
    override func update(_ currentTime: TimeInterval) {
        /// UI Field update
        updateSpringFields()
        
        /// camera inertia
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.updateInertia()
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
                //body.collisionBitMask = 0
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
