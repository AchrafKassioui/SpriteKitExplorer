/**
 
 # Filtering Mode
 
 Exploring the filtering modes available on sprite nodes and shape nodes.
 
 Achraf Kassioui
 Created: 22 May 2024
 Updated: 22 May 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

struct FilteringModeView: View {
    @State private var sceneId = UUID()
    var scene = FilteringModeScene()
    
    var body: some View {
        VStack (spacing: 0) {
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
            .ignoresSafeArea(.all, edges: [.top, .trailing, .leading])
            
            VStack {
                menuBar()
            }
        }
        .background(.black)
    }
    
    private func menuBar() -> some View {
        HStack {
            Spacer()
            resetCameraButton
            togglePhysicsButton
            debugButton
            Spacer()
        }
        .padding([.top, .leading, .trailing], 10)
        .background(.ultraThinMaterial)
        .shadow(radius: 10)
    }
    
    private var resetCameraButton: some View {
        Button(action: {
            scene.resetCamera()
        }, label: {
            Image("camera-reset-icon")
                .colorInvert()
        })
        .buttonStyle(roundButtonStyle())
    }
    
    private var togglePhysicsButton: some View {
        Button(action: {
            scene.toggleAdaptiveFiltering()
        }) {
            Text("A")
        }
        .buttonStyle(roundButtonStyle())
    }
    
    private var debugButton: some View {
        Button(action: {
            if let view = scene.view {
                scene.toggleDebugOptions(view: view)
            }
        }, label: {
            Image("scope-icon")
                .colorInvert()
        })
        .buttonStyle(roundButtonStyle())
    }
}

#Preview {
    FilteringModeView()
}

// MARK: SpriteKit

class FilteringModeScene: SKScene {
    
    // MARK: - didMove
    
    override func didMove(to view: SKView) {
        /// configure view
        size = view.bounds.size
        scaleMode = .resizeFill
        view.contentMode = .center
        backgroundColor = .gray
        backgroundColor = SKColor(red: 0.89, green: 0.89, blue: 0.84, alpha: 1)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        view.isMultipleTouchEnabled = true
        
        cleanPhysics()
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        /// create background
        let gridTexture = generateGridTexture(cellSize: 150, rows: 17, cols: 17, linesColor: SKColor(white: 0, alpha: 0.9))
        let gridbackground = SKSpriteNode(texture: gridTexture)
        gridbackground.zPosition = -1
        objectsLayer.addChild(gridbackground)
        
        /// create camera
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.minScale = 0.01
        camera = inertialCamera
        addChild(inertialCamera)
        
        /// filters
        let myFilter = CIFilter.pixellate()
        effectLayer.filter = ChainCIFilter(filters: [myFilter])
        effectLayer.shouldEnableEffects = false
        
        /// populate scene
        createSceneLayers(camera: inertialCamera)
        createSprite(parent: objectsLayer)
        
        let box = SKShapeNode(rectOf: CGSize(width: 100, height: 10))
        box.lineWidth = 3
        box.zPosition = 10
        box.zRotation = 0.25
        objectsLayer.addChild(box)
    }
    
    // MARK: - Scene Setup
    
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
    
    let uiLayer = SKNode()
    let effectLayer = SKEffectNode()
    let objectsLayer = SKNode()
    var objectBoundaries = SKShapeNode()
    
    func createSceneLayers(camera: SKCameraNode) {
        uiLayer.zPosition = 9999
        camera.addChild(uiLayer)
        
        effectLayer.zPosition = 1
        addChild(effectLayer)
        
        objectsLayer.zPosition = 2
        effectLayer.addChild(objectsLayer)
    }
    
    // MARK: - Camera
    
    func resetCamera() {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.setTo(position: .zero, xScale: 1, yScale: 1, rotation: 0)
        }
    }
    
    /**
     
     Toggle the filtering mode for sprites and shapes
     
     */
    var smoothing = true
    func toggleAdaptiveFiltering() {
        if let inertialCamera = camera as? InertialCamera {
            if !smoothing {
                inertialCamera.adaptiveFilteringParent = objectsLayer
                inertialCamera.setSmoothing(to: !smoothing, forChildrenOf: objectsLayer)
            } else {
                inertialCamera.adaptiveFilteringParent = nil
                smoothing.toggle()
            }
        }
    }
    
    // MARK: - Objects
    
    func createSprite(parent: SKNode) {
        let sprite = SKSpriteNode(texture: SKTexture(imageNamed: "woman"))
        sprite.colorBlendFactor = 0
        sprite.color = .systemYellow
        sprite.position.y = -470
        sprite.position.x = 40
        setupPhysicsCategories(node: sprite, as: .sceneBody)
        
        parent.addChild(sprite)
    }
    
    // MARK: - Update
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.update()
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
}
