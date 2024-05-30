/**
 
 # SpriteKit Physics Scale
 
 Achraf Kassioui
 Created: 19 May 2024
 Updated: 19 May 2024
 
 */
import SwiftUI
import SpriteKit

// MARK: SwiftUI

struct PhysicsScaleView: View {
    @State private var sceneId = UUID()
    @State var isPaused = false
    @State var isCameraLocked = false
    @State var isGravityOn = false
    var scene = PhysicsScaleScene()
    
    var body: some View {
        VStack(spacing: 0) {
            SpriteView(
                scene: scene,
                options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes]
            )
            /// force recreation using the unique ID
            .id(sceneId)
            .onAppear {
                /// generate a new ID on each appearance
                sceneId = UUID()
            }
            .ignoresSafeArea(.all, edges: [.top, .trailing, .bottom, .leading])
            
            VStack {
                dockedMenuBar()
            }
        }
        .background(Color(SKColor.black))
    }
    
    private func dockedMenuBar() -> some View {
        HStack (spacing: 1) {
            Spacer()
            playPauseButton
            toggleGravityButton
            resetCameraButton
            lockCameraButton
            debugButton
            Spacer()
        }
        .padding([.top, .leading, .trailing], 10)
        .background(.ultraThinMaterial)
        .shadow(radius: 10)
    }
    
    private func menuBar() -> some View {
        HStack (spacing: 1) {
            playPauseButton
            toggleGravityButton
            resetCameraButton
            lockCameraButton
            debugButton
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.black.opacity(0.6), lineWidth: 1)
                //.fill(.black.opacity(0.2))
        }
        .padding([.top, .leading, .trailing], 10)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 10)
    }
    
    private var lockCameraButton: some View {
        Button(action: {
            isCameraLocked.toggle()
            scene.toggleCameraLock()
        }, label: {
            Image(isCameraLocked ? "camera-lock-icon" : "camera-unlock-icon")
        })
        .buttonStyle(squareButtonStyle())
    }
    
    private var resetCameraButton: some View {
        Button(action: {
            scene.resetCamera()
        }, label: {
            Image("camera-reset-icon")
        })
        .buttonStyle(squareButtonStyle())
    }
    
    private var playPauseButton: some View {
        Button(action: {
            isPaused.toggle()
            scene.pauseScene(isPaused)
        }) {
            Image(isPaused ? "play-icon" : "pause-icon")
        }
        .buttonStyle(squareButtonStyle())
    }
    
    private var toggleGravityButton: some View {
        Button(action: {
            isGravityOn.toggle()
            scene.sceneGravity = isGravityOn
        }) {
            Image(isGravityOn ? "gravity-icon" : "gravity-off-icon")
        }
        .buttonStyle(squareButtonStyle())
    }
    
    private var debugButton: some View {
        Button(action: {
            if let view = scene.view {
                scene.toggleDebugOptions(view: view)
            }
        }, label: {
            Image("chart-bar-icon")
        })
        .buttonStyle(squareButtonStyle())
    }
}

#Preview {
    PhysicsScaleView()
}

// MARK: SpriteKit

class PhysicsScaleScene: SKScene {
    
    // MARK: - didMove
    
    override func didMove(to view: SKView) {
        /// configure view
        size = view.bounds.size
        scaleMode = .resizeFill
        view.contentMode = .center
        backgroundColor = SKColor(displayP3Red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        backgroundColor = .darkGray
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        view.isMultipleTouchEnabled = true
        
        cleanPhysics()
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        /// create background
        let gridTexture = generateGridTexture(cellSize: 150, rows: 17, cols: 17, linesColor: SKColor(white: 1, alpha: 0.2))
        let gridbackground = SKSpriteNode(texture: gridTexture)
        gridbackground.zPosition = -1
        objectsLayer.addChild(gridbackground)
        
        /// create camera
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.lockRotation = true
        inertialCamera.minScale = 0.2
        inertialCamera.maxScale = 20
        camera = inertialCamera
        addChild(inertialCamera)
        
        /// filters
        let myFilter = CIFilter.bloom()
        effectLayer.filter = ChainCIFilter(filters: [myFilter])
        effectLayer.shouldEnableEffects = false
        
        /// populate scene
        createSceneLayers(camera: inertialCamera)
        createZoomDisplay(view: view, parent: uiLayer)
        updateZoomLabel()
        createPhysicalBoundaryForUIBodies(view: view, parent: uiLayer)
        createPhysicalBoundaryForSceneBodies(size: view.bounds.size)

        createPinnedObjectFromTwoPoints(parent: uiLayer, as: .UIBody)
    }
    
    // MARK: - Scene Setup
    
    let uiLayer = SKNode()
    let effectLayer = SKEffectNode()
    let objectsLayer = SKNode()
    
    func pauseScene(_ isPaused: Bool) {
        self.objectsLayer.isPaused = isPaused
        self.physicsWorld.speed = isPaused ? 0 : 1
    }
    
    var sceneGravity = false {
        didSet {
            if sceneGravity { self.physicsWorld.gravity = CGVector(dx: 0, dy: -20) }
            else { self.physicsWorld.gravity = CGVector(dx: 0, dy: 0) }
        }
    }
    
    var simulatePhysics = true {
        didSet {
            if simulatePhysics { self.physicsWorld.speed = 1 }
            else { self.physicsWorld.speed = 0 }
        }
    }
    
    func createSceneLayers(camera: SKCameraNode) {
        uiLayer.zPosition = 9999
        camera.addChild(uiLayer)
        
        effectLayer.zPosition = 1
        addChild(effectLayer)
        
        objectsLayer.zPosition = 2
        effectLayer.addChild(objectsLayer)
    }
    
    // MARK: - Camera
    
    var zoomLabel = SKLabelNode()
    
    func freeCamera() {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.lock = false
        }
    }
    
    func lockCamera() {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.lock = true
        }
    }
    
    func toggleCameraLock() {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.stopInertia()
            inertialCamera.lock.toggle()
        }
    }
    
    func resetCamera() {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.stopInertia()
            inertialCamera.setTo(position: .zero, xScale: 1, yScale: 1, rotation: 0)
        }
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
    
    // MARK: - Physics setup
    
    func createPhysicalBoundaryForSceneBodies(size: CGSize) {
        let factor: CGFloat = 1
        
        let physicsBoundaries = CGRect(
            x: -size.width/2,
            y: (-size.height * factor) / 2,
            width: size.width,
            height: size.height * factor
        )
        
        let boundaryForSceneBodies = SKShapeNode(rect: physicsBoundaries)
        boundaryForSceneBodies.lineWidth = 3
        boundaryForSceneBodies.lineJoin = .round
        boundaryForSceneBodies.strokeColor = SKColor(white: 0, alpha: 1)
        boundaryForSceneBodies.fillColor = SKColor(white: 1, alpha: 0.1)
        boundaryForSceneBodies.physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBoundaries)
        setupPhysicsCategories(node: boundaryForSceneBodies, as: .sceneBoundary)
        boundaryForSceneBodies.physicsBody?.restitution = 0
        boundaryForSceneBodies.zPosition = -1
        addChild(boundaryForSceneBodies)
    }
    
    func createPhysicalBoundaryForUIBodies(view: SKView, parent: SKNode) {
        let margin: CGFloat = 0
        
        let viewSafeArea = CGRect(
            x: -view.bounds.width/2 - margin/2,
            y: -view.bounds.height/2 - margin/2,
            width: view.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right + margin,
            height: view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom + margin
        )
        
        let viewSafeAreaFrame = SKShapeNode(rect: viewSafeArea)
        viewSafeAreaFrame.lineWidth = 0
        viewSafeAreaFrame.strokeColor = .magenta
        viewSafeAreaFrame.physicsBody = SKPhysicsBody(edgeLoopFrom: viewSafeArea)
        setupPhysicsCategories(node: viewSafeAreaFrame, as: .UIBoundary)
        viewSafeAreaFrame.physicsBody?.restitution = 0
        viewSafeAreaFrame.physicsBody?.friction = 0
        parent.addChild(viewSafeAreaFrame)
    }
    
    // MARK: - Scene Objects
    
    func createSceneBody(view: SKView, parent: SKNode) {
        let sprite = SKSpriteNode(texture: SKTexture(imageNamed: "rectangle-60-20-fill"))
        sprite.colorBlendFactor = 1
        sprite.color = .systemCyan
        sprite.setScale(1)
        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        setupPhysicsCategories(node: sprite, as: .sceneBody)
        sprite.physicsBody?.linearDamping = 1
        sprite.physicsBody?.restitution = 0
        
        let label = createSpriteLabel(view: view, text: "Scene", color: .black, size: 20)
        label.zPosition = 1
        sprite.addChild(label)
        
        parent.addChild(sprite)
    }
    
    // MARK: - Debugging Joints
    
    let rectangle = SKSpriteNode()
    let anchorPoint1 = SKNode()
    let anchorPoint2 = SKNode()
    
    func createPinnedObjectFromTwoPoints(parent: SKNode, as physicsCategory: PhysicsCategory) {
        
        /// The pinned sprite
        rectangle.texture = SKTexture(imageNamed: "rectangle-60-12-fill")
        rectangle.colorBlendFactor = 1
        rectangle.color = .systemYellow
        rectangle.centerRect = setCenterRect(cornerWidth: 12, cornerHeight: 12, spriteNode: rectangle)
        rectangle.size = CGSize(width: 140, height: 60)
        rectangle.name = "flickable"
        rectangle.physicsBody = SKPhysicsBody(rectangleOf: rectangle.size)
        setupPhysicsCategories(node: rectangle, as: physicsCategory)
        rectangle.physicsBody?.affectedByGravity = true
        rectangle.physicsBody?.allowsRotation = true
        rectangle.position = CGPoint(x: 0, y: -100)
        parent.addChild(rectangle)
        
        /// Create the first anchor point
        anchorPoint1.position = CGPoint(x: -50, y: 200)
        anchorPoint1.physicsBody = SKPhysicsBody(circleOfRadius: 1)
        setupPhysicsCategories(node: anchorPoint1, as: physicsCategory)
        anchorPoint1.physicsBody?.isDynamic = false
        anchorPoint1.physicsBody?.angularDamping = 0
        parent.addChild(anchorPoint1)
        
        /// Create the second anchor point
        anchorPoint2.position = CGPoint(x: 50, y: 200)
        anchorPoint2.physicsBody = SKPhysicsBody(circleOfRadius: 1)
        setupPhysicsCategories(node: anchorPoint2, as: physicsCategory)
        anchorPoint2.physicsBody?.isDynamic = false
        parent.addChild(anchorPoint2)
        
        /// Pin joints
        let pinJoint1 = SKPhysicsJointPin.joint(
            withBodyA: rectangle.physicsBody!,
            bodyB: anchorPoint1.physicsBody!,
            anchor: anchorPoint1.position
        )
        pinJoint1.frictionTorque = 1
        pinJoint1.rotationSpeed = 1
        
        let pinJoint2 = SKPhysicsJointPin.joint(
            withBodyA: rectangle.physicsBody!,
            bodyB: anchorPoint2.physicsBody!,
            anchor: anchorPoint2.position
        )
        pinJoint2.frictionTorque = 0
        
        //physicsWorld.add(pinJoint1)
        //physicsWorld.add(pinJoint2)
        
        /// Spring joints
        let springJoint1 = SKPhysicsJointSpring.joint(
            withBodyA: rectangle.physicsBody!,
            bodyB: anchorPoint1.physicsBody!,
            anchorA: rectangle.position,
            anchorB: anchorPoint1.position
        )
        springJoint1.frequency = 1
        springJoint1.damping = 0
        
        let springJoint2 = SKPhysicsJointSpring.joint(
            withBodyA: rectangle.physicsBody!,
            bodyB: anchorPoint2.physicsBody!,
            anchorA: rectangle.position,
            anchorB: anchorPoint2.position
        )
        springJoint2.frequency = 1
        springJoint2.damping = 0
        
        physicsWorld.add(springJoint1)
        physicsWorld.add(springJoint2)
    }
    
    // MARK: - UI
    
    func createPalette(view: SKView, parent: SKNode) {
        let paletteSize = CGSize(width: 60, height: 380)
        
        let palette = generatePalette(size: paletteSize, view: view)
        setupPhysicsCategories(node: palette, as: .UIBody)
        palette.physicsBody?.affectedByGravity = true
        palette.physicsBody?.allowsRotation = false
        palette.physicsBody?.restitution = 0
        palette.physicsBody?.linearDamping = 0
        palette.constraints = [createConstraintsInView(view: view, node: palette, region: .leftEdge, margin: 10, vizParent: nil)]
        parent.addChild(palette)
        
        let cameraControlToggle = ToggleSwitch(
            iconON: SKTexture(imageNamed: "camera-unlock-icon"),
            iconOFF: SKTexture(imageNamed: "camera-lock-icon"),
            onTouchBegan: {
                print("toggle touch began")
                self.freeCamera()
            },
            onTouchEnded: {
                print("toggle touch ended")
                self.lockCamera()
            }
        )
        cameraControlToggle.zPosition = 10
        
        let toggleArray = [cameraControlToggle]
        distributeNodes(direction: .vertical, container: palette, nodes: toggleArray, spacing: 1)
    }
    
    /**
     
     # Generate Palette with clipping
     
     */
    func generatePaletteWithClipping(size paletteSize: CGSize, view: SKView) -> SKCropNode {
        let strokeColor = SKColor(white: 0, alpha: 0.6)
        let fillColor: SKColor = SKColor(white: 0, alpha: 0.8)
        let strokeWidth: CGFloat = 2
        let bodyExtension: Double = 0
        let paletteSizeWithStroke = CGSize(width: paletteSize.width + strokeWidth, height: paletteSize.height + strokeWidth)
        
        /// palette shape
        let paletteShape = SKShapeNode(rectOf: paletteSizeWithStroke, cornerRadius: 12)
        paletteShape.lineWidth = strokeWidth
        paletteShape.strokeColor = strokeColor
        paletteShape.fillColor = fillColor
        
        /// palette
        let paletteSprite = SKSpriteNode(texture: view.texture(from: paletteShape))
        paletteSprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(
            width: paletteSizeWithStroke.width + bodyExtension,
            height: paletteSizeWithStroke.height + bodyExtension
        ))
        
        /// palette shadow
        let shadowSprite = SKSpriteNode(
            texture: generateShadowTexture(
                width: paletteSizeWithStroke.width,
                height: paletteSizeWithStroke.height,
                cornerRadius: 12,
                shadowOffset: CGSize(width: 0, height: 0),
                shadowBlurRadius: 32,
                shadowColor: SKColor(white: 0, alpha: 0.4)
            )
        )
        shadowSprite.zPosition = -1
        shadowSprite.blendMode = .alpha
        paletteSprite.addChild(shadowSprite)
        
        /// mask node
        let maskNode = SKShapeNode(rectOf: paletteSizeWithStroke, cornerRadius: 12)
        maskNode.fillColor = .white
        maskNode.lineWidth = 0
        
        /// crop node with mask
        let cropNode = SKCropNode()
        cropNode.maskNode = maskNode
        cropNode.addChild(paletteSprite)
        
        return cropNode
    }
    
    /**
     
     # Palette constructor
     
     */
    func generatePalette(size paletteSize: CGSize, view: SKView) -> SKSpriteNode {
        let strokeColor = SKColor(white: 0, alpha: 0.6)
        let fillColor: SKColor = SKColor(white: 0, alpha: 0.8)
        let strokeWidth: CGFloat = 2
        let bodyExtension: Double = 0
        let paletteSize = CGSize(width: paletteSize.width+strokeWidth, height: paletteSize.height+strokeWidth)
        
        /// palette shape
        let paletteShape = SKShapeNode(rectOf: paletteSize, cornerRadius: 12)
        paletteShape.lineWidth = strokeWidth
        paletteShape.strokeColor = strokeColor
        paletteShape.fillColor = fillColor
        
        /// palette
        let paletteSprite = SKSpriteNode(texture: view.texture(from: paletteShape))
        paletteSprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(
            width: paletteSize.width + bodyExtension,
            height: paletteSize.height + bodyExtension
        ))
        //paletteSprite.zPosition = 1
        
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
        paletteSprite.addChild(shadowSprite)
        
        return paletteSprite
    }
    
    /**
     
     # A body attached to the camera
     
     */
    func createBodyInCamera(view: SKView, parent: SKNode) {
        let uiBody = SKSpriteNode(texture: SKTexture(imageNamed: "rectangle-60-20-fill"))
        uiBody.name = "UIBody"
        uiBody.colorBlendFactor = 1
        uiBody.color = .darkGray
        uiBody.physicsBody = SKPhysicsBody(texture: uiBody.texture!, size: uiBody.texture!.size())
        setupPhysicsCategories(node: uiBody, as: .UIBody)
        uiBody.physicsBody?.affectedByGravity = true
        uiBody.physicsBody?.allowsRotation = false
        uiBody.physicsBody?.linearDamping = 0
        uiBody.physicsBody?.restitution = 0
        
        uiBody.constraints = [createConstraintsInView(view: view, node: uiBody, region: .view, margin: 20, vizParent: nil)]
        
        let label = createSpriteLabel(view: view, text: "UI", color: .white, size: 20)
        label.zPosition = 1
        uiBody.addChild(label)
        
        parent.addChild(uiBody)
    }
    
    // MARK: - Update
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.updateInertia()
            updateZoomLabel()
        }
        
        if let _ = childNode(withName: "//UIBody") as? SKSpriteNode {
            //print(uiBody.physicsBody?.velocity)
        }
    }
    
    // MARK: - Touches Began
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            if let inertialCamera = camera as? InertialCamera {
                inertialCamera.stopInertia()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            enumerateChildNodes(withName: "//UIBody", using: {node, _ in
                //print(node.physicsBody?.velocity)
            })
        }
    }
}
