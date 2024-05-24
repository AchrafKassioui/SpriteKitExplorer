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
        .background(Color(SKColor.darkGray))
    }
    
    private func dockedMenuBar() -> some View {
        HStack (spacing: 1) {
            Spacer()
            togglePhysicsButton
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
            togglePhysicsButton
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
                .colorInvert()
        })
        .buttonStyle(squareButtonStyle())
    }
    
    private var resetCameraButton: some View {
        Button(action: {
            scene.resetCamera()
        }, label: {
            Image("camera-reset-icon")
                .colorInvert()
        })
        .buttonStyle(squareButtonStyle())
    }
    
    private var togglePhysicsButton: some View {
        Button(action: {
            isPaused.toggle()
            scene.simulatePhysics = isPaused ? false : true
        }) {
            Image(isPaused ? "physics-off-icon" : "physics-on-icon")
        }
        .buttonStyle(squareButtonStyle())
    }
    
    private var toggleGravityButton: some View {
        Button(action: {
            isGravityOn.toggle()
            scene.sceneGravity = isGravityOn
        }) {
            Image(isGravityOn ? "gravity-icon" : "gravity-off-icon")
                .colorInvert()
        }
        .buttonStyle(squareButtonStyle())
    }
    
    private var debugButton: some View {
        Button(action: {
            if let view = scene.view {
                scene.toggleDebugOptions(view: view)
            }
        }, label: {
            Image("square-dashed-icon")
                .colorInvert()
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
        //view.contentMode = .center
        backgroundColor = SKColor(displayP3Red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        backgroundColor = .gray
        //anchorPoint = CGPoint(x: 0.5, y: 0.5)
        view.isMultipleTouchEnabled = true
        
        cleanPhysics()
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        /// create background
        let gridTexture = generateGridTexture(cellSize: 150, rows: 17, cols: 17, linesColor: SKColor(white: 0, alpha: 0.4))
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
        
        createUIBody(view: view, parent: uiLayer)
        createSceneBody(view: view, parent: objectsLayer)
    }
    
    // MARK: - Scene Setup
    
    let uiLayer = SKNode()
    let effectLayer = SKEffectNode()
    let objectsLayer = SKNode()
    
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
        boundaryForSceneBodies.lineWidth = 10
        boundaryForSceneBodies.lineJoin = .round
        boundaryForSceneBodies.strokeColor = SKColor(white: 0, alpha: 1)
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
    
    // MARK: - UI Objects
    
    func createUIBody(view: SKView, parent: SKNode) {
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
        
        let label = createSpriteLabel(view: view, text: "UI", color: .black, size: 20)
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
