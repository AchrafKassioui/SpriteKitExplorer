/**
 
 # Render Region in Screen
 
 This setup demonstrates how we can use SpriteKit to record a region of the screen in real-time.
 We use `view.texture(from:crop:)`. That method takes a region in scene coordinates. If the camera zooms out, the region will get bigger, and so would the texture.
 We don't want that. Instead, we want a rendered texture of fixed size regardless of camera zoom (i.e. camera scale).
 
 The `renderRegion()` function continuously renders live snapshots of a defined region, after doing the necessary processing to compensate for camera zoom and pan.
 The function compensates for camera scale (zoom) and position (pan), but not rotation (TDB).
 In addition to defining a fixed render size in points, we can also minimize the work done by the GPU by rendering at @1x instead of @2x or @3x.
 
 After snapshotting the region, we can apply Core Image filters to the rendered result.
 Performance is good and the whole setup is promissing.
 
 ## Notes on Performance
 - On this setup, when the camera is at 100%, it is cheaper to render the scene through live snapshotting
 - Hiding the scene layer after snapshotting a region of it, and displaying the rendered texture instead, significantly minimizes the overhead of drawing into a separate pass using `texture(from:)`
 - Most of the performance challenges were due to CPU, not GPU.
 - GPU cost spikes up with some Core Image filters. Otherwise its seems reasonable.
 
 ## Todo
 - Compensate for camera rotation.
 - Understand why CPU usage spikes up in certain scenarios when recording is ON. Typically, with high particle count with a close up camera.
 
 Achraf Kassioui
 Created 27 November 2024
 Updated 2 December 2024
 
 */

import SwiftUI
import SpriteKit
import AVFoundation

struct RenderRegionView: View {
    @State private var sceneID = UUID()
    var body: some View {
        SpriteView(
            scene: RenderRegionScene(),
            options: [.shouldCullNonVisibleNodes]
            ,debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount, .showsQuadCount]
        )
        .id(sceneID)
        .onAppear { sceneID = UUID() }
        .background(Color(SKColor.black))
        .persistentSystemOverlays(.hidden)
    }
}

#Preview {
    RenderRegionView()
}

class RenderRegionScene: SKScene {
    
    // MARK: Properties
    
    var inertialCamera: InertialCamera?
    
    let uiLayer = SKNode()
    let sceneLayer = SKNode()
    
    let snapshotContainer = SKSpriteNode()
    var cropShape = SKShapeNode()
    var isSnapshotting: Bool = false
    
    var currentSimulationTime: TimeInterval = 0
    
    // MARK: Scene Setup
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        view.contentScaleFactor = 2 /// When this value is equal or less than 1 (but not 0), the Metal Graphics HUD renders at 1x on a 3x display
        
        createCamera()
        createLayers()
        
        createSomeNodes(parent: sceneLayer, view: view)
        
        createCropUI(parent: uiLayer, view: view)
        createSnapshotContainer(parent: uiLayer, view: view)
        
        createPlayPauseButton(parent: uiLayer, view: view)
        createSnapshotButton(parent: uiLayer, view: view)
        createCameraZoomLabel(parent: uiLayer, view: view)
        createButtonA(parent: uiLayer, view: view)
        createButtonB(parent: uiLayer, view: view)
    }
    
    func createCamera() {
        inertialCamera = InertialCamera(scene: self)
        camera = inertialCamera
        inertialCamera?.maxScale = 20
        inertialCamera?.lockRotation = true
        inertialCamera?.doubleTapToReset = false
        inertialCamera?.zPosition = 1000
        inertialCamera?.setTo(position: .zero, xScale: 4, yScale: 4, rotation: 0)
        if let inertialCamera = inertialCamera { addChild(inertialCamera) }
    }
    
    func createLayers() {
        guard let camera = camera else { return }
        camera.addChild(uiLayer)
        addChild(sceneLayer)
    }
    
    // MARK: Snapshot UI
    
    /// Create the crop UI shape before the snapshot container, because we need the cropUI dimensions
    func createCropUI(parent: SKNode, view: SKView) {
        let sizeToRender = CGSize(width: 360, height: 600)
        
        cropShape = SKShapeNode(rect: CGRect(
            x: -sizeToRender.width / 2,
            y: -sizeToRender.height / 2,
            width: sizeToRender.width,
            height: sizeToRender.height
        ))
        cropShape.lineWidth = 3
        cropShape.strokeColor = .black
        cropShape.lineJoin = .round
        parent.addChild(cropShape)
    }
    
    func createSnapshotContainer(parent: SKNode, view: SKView) {
        parent.addChild(snapshotContainer)
        
        guard let cropShapeRect = cropShape.path?.boundingBox else { return }
        let padding: CGFloat = 10
        
        let label = SKLabelNode()
        label.verticalAlignmentMode = .top
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: -cropShapeRect.width/2 + padding, y: cropShapeRect.height/2 - padding)
        snapshotContainer.addChild(label)
        
        let text = "🔴 REC"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "AvenirNext-Bold", size: 22) ?? .systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: SKColor.white,
            .strokeColor: SKColor.black,
            .strokeWidth: -3,
        ]
        
        label.attributedText = NSAttributedString(string: text, attributes: attributes)
    }
    
    // MARK: UI
    
    /// I use this button for various testing
    func createButtonB(parent: SKNode, view: SKView) {
        let shape = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 18)
        shape.lineWidth = 2
        shape.strokeColor = SKColor(white: 0, alpha: 0.6)
        shape.fillColor = .white
        
        let button = SKSpriteNode()
        button.name = "buttonB"
        button.colorBlendFactor = 1
        button.color = .darkGray
        if let texture = view.texture(from: shape) {
            button.texture = texture
            button.size = texture.size()
            button.position = CGPoint(x: 60, y: -340)
            parent.addChild(button)
        }
        
        let icon = SKSpriteNode(texture: SKTexture(imageNamed: "b-icon"), color: .white, size: CGSize(width: 32, height: 32))
        icon.name = "buttonB"
        button.addChild(icon)
    }
    
    func createButtonA(parent: SKNode, view: SKView) {
        let shape = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 18)
        shape.lineWidth = 2
        shape.strokeColor = SKColor(white: 0, alpha: 0.6)
        shape.fillColor = .white
        
        let button = SKSpriteNode()
        button.name = "buttonA"
        button.colorBlendFactor = 1
        button.color = .darkGray
        if let texture = view.texture(from: shape) {
            button.texture = texture
            button.size = texture.size()
            button.position = CGPoint(x: -10, y: -340)
            parent.addChild(button)
        }
        
        let icon = SKSpriteNode(texture: SKTexture(imageNamed: "a-icon"), color: .white, size: CGSize(width: 32, height: 32))
        icon.name = "buttonA"
        button.addChild(icon)
    }
    
    func createCameraZoomLabel(parent: SKNode, view: SKView) {
        let shape = SKShapeNode(rectOf: CGSize(width: 60, height: 40), cornerRadius: 10)
        shape.lineWidth = 2
        shape.strokeColor = SKColor(white: 0, alpha: 0.6)
        shape.fillColor = .white
        
        let container = SKSpriteNode()
        container.name = "cameraZoom"
        container.colorBlendFactor = 1
        container.color = .darkGray
        if let texture = view.texture(from: shape) {
            container.texture = texture
            container.size = texture.size()
            container.position = CGPoint(x: -150, y: 350)
            parent.addChild(container)
        }
        
        let label = SKLabelNode(text: "100%")
        label.name = "cameraZoomLabel"
        label.fontName = "AvenirNext-Medium"
        label.fontSize = 16
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: -7)
        label.horizontalAlignmentMode = .center
        container.addChild(label)
    }
    
    func createSnapshotButton(parent: SKNode, view: SKView) {
        let shape = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 18)
        shape.lineWidth = 2
        shape.strokeColor = SKColor(white: 0, alpha: 0.6)
        shape.fillColor = .white
        
        let button = SKSpriteNode()
        button.name = "snapshot"
        button.colorBlendFactor = 1
        button.color = .darkGray
        if let texture = view.texture(from: shape) {
            button.texture = texture
            button.size = texture.size()
            button.position = CGPoint(x: -80, y: -340)
            parent.addChild(button)
        }
        
        let icon = SKSpriteNode(texture: SKTexture(imageNamed: "record-icon"), color: .white, size: CGSize(width: 24, height: 24))
        icon.name = "snapshot"
        button.addChild(icon)
    }
    
    func createPlayPauseButton(parent: SKNode, view: SKView) {
        let shape = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 18)
        shape.lineWidth = 2
        shape.strokeColor = SKColor(white: 0, alpha: 0.6)
        shape.fillColor = .white
        
        let button = SKSpriteNode()
        button.name = "playpause"
        button.colorBlendFactor = 1
        button.color = .darkGray
        if let texture = view.texture(from: shape) {
            button.texture = texture
            button.size = texture.size()
            button.position = CGPoint(x: -150, y: -340)
            parent.addChild(button)
        }
        
        let icon = SKSpriteNode(texture: SKTexture(imageNamed: "play-pause-icon"), color: .white, size: CGSize(width: 24, height: 24))
        icon.name = "playpause"
        button.addChild(icon)
    }
    
    // MARK: Create some Nodes
    /**
     
     We populate the scene to stress out the CPU and GPU.
     
     */
    func createSomeNodes(parent: SKNode, view: SKView) {
        let physicsFrame = CGRect(x: -1000, y: -2000, width: 2000, height: 4000)
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: physicsFrame)
        physicsWorld.gravity = CGVector(dx: 0, dy: -10)
        /// physicsWorld speed apply to physics bodies, not particles.
        /// increasing speed increases the CPU load. Higher speed make recording choppier.
        physicsWorld.speed = 1
        
        /// A background sprite of some color
        /// This maintains the color blending of the nodes rendered with `view.texture(from:)`
        let background = SKSpriteNode(color: self.backgroundColor, size: physicsFrame.size)
        parent.addChild(background)
        
        /// Horizontal and vertical ticks
        func createSprites(parent: SKNode, count: Int, spacing: CGFloat, size: CGSize, isHorizontal: Bool) {
            let totalLength = CGFloat(count) * spacing - spacing
            let start = -totalLength / 2
            
            for i in 0..<count {
                let sprite = SKSpriteNode(color: .black, size: size)
                if isHorizontal {
                    sprite.position = CGPoint(x: start + CGFloat(i) * spacing, y: 0)
                } else {
                    sprite.position = CGPoint(x: 0, y: start + CGFloat(i) * spacing)
                }
                parent.addChild(sprite)
            }
        }
        createSprites(parent: parent, count: 1000, spacing: 150, size: CGSize(width: 10, height: 150), isHorizontal: true)
        createSprites(parent: parent, count: 1000, spacing: 150, size: CGSize(width: 150, height: 10), isHorizontal: false)
        
        /// A bunch of physical nodes
        /// Heavy on the CPU
        let shapeRadius: CGFloat = 15
        let xRange = SKRange(lowerLimit: physicsFrame.minX + shapeRadius, upperLimit: physicsFrame.maxX - shapeRadius)
        let yRange = SKRange(lowerLimit: physicsFrame.minY + shapeRadius, upperLimit: physicsFrame.maxY - shapeRadius)
        let lockInsideFrame = SKConstraint.positionX(xRange, y: yRange)
        
        let shape = SKShapeNode(circleOfRadius: shapeRadius)
        shape.fillColor = .white
        shape.lineWidth = 6
        shape.strokeColor = .black
        
        let texture = view.texture(from: shape)
        //let heavierTexture = SKTexture(imageNamed: "smoke_128*128")
        
        for i in 1...1000 {
            let sprite = SKSpriteNode(texture: texture)
            sprite.name = "physicsBody"
            sprite.physicsBody = SKPhysicsBody(circleOfRadius: shapeRadius)
            sprite.physicsBody?.charge = -0.1
            sprite.constraints = [lockInsideFrame]
            
            run(SKAction.wait(forDuration: Double(i) * 0.01)) {
                parent.addChild(sprite)
            }
        }
        
        /// Particles
        /// Heavy on the GPU
        if let emitter = SKEmitterNode(fileNamed: "FireLarge") {
            emitter.fieldBitMask = 1
            emitter.name = "emitter"
            //emitter.particlePositionRange = CGVector(dx: physicsFrame.width/4, dy: physicsFrame.height/4)
            //emitter.particleBirthRate = 20000
            emitter.targetNode = parent
            parent.addChild(emitter)
        }
        
        /// Video
        if let filePath = Bundle.main.path(forResource: "Cars on Bridge - Legio Seven - SD", ofType: "mp4") {
            let fileURL = URL(fileURLWithPath: filePath)
            let player = AVPlayer(url: fileURL)
            player.rate = 3
            
            /// Sometimes, while recording, the video doesn't loop. Need to invesitigate that
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                player.seek(to: CMTime.zero)
                player.play()
                player.rate = 3
            }
            
            let videoNode = SKVideoNode(avPlayer: player)
            videoNode.name = "videoNode"
            videoNode.position = CGPoint(x: physicsFrame.minX + 500, y: physicsFrame.maxY - 800)
            videoNode.zPosition = 1
            parent.addChild(videoNode)
        }
        
        /// Video 2
        if let filePath = Bundle.main.path(forResource: "Multi-touch typography", ofType: "mp4") {
            let fileURL = URL(fileURLWithPath: filePath)
            let player = AVPlayer(url: fileURL)
            player.rate = 1
            
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                player.seek(to: .zero)
                player.play()
                player.rate = 1
            }
            
            let videoNode = SKVideoNode(avPlayer: player)
            videoNode.name = "videoNode"
            videoNode.position = CGPoint(x: physicsFrame.maxX - 500, y: physicsFrame.maxY - 800)
            videoNode.zPosition = 1
            parent.addChild(videoNode)
        }
        
        /// Physics fields
        /// Apply to both physics bodies and particles.
        /// A lot of particles under physics fields are heavy on the CPU
        let eField = SKFieldNode.electricField()
        eField.name = "field"
        eField.position = CGPoint(x: -1, y: -1)
        eField.minimumRadius = 5
        eField.strength = 5
        parent.addChild(eField)
        
        let mField = SKFieldNode.noiseField(withSmoothness: 1, animationSpeed: 1)
        mField.name = "field"
        mField.position = CGPoint(x: 1, y: 1)
        mField.minimumRadius = 150
        mField.strength = 10
        parent.addChild(mField)
        
        let gField = SKFieldNode.radialGravityField()
        gField.name = "field"
        gField.position = CGPoint(x: 0, y: 200)
        gField.strength = -5
        gField.region = SKRegion(radius: 100)
        parent.addChild(gField)
    }
    
    // MARK: Render Region
    /**
     
     This is the main capture function. It's called in `didFinishUpdate`.
     Before and after calling the function, we hide or show the nodes we want to include in the capture.
     We use `view.texture(from)` to get a render. That renders the scene in a separate GPU pass.
     With the right setup, the overhead of a separate render pass can be greatly mitigated, and in some cases, it's even cheaper to render the whole view this way.
     
     */
    func renderRegion() {
        guard let view = view, let camera = camera else { return }
        
        let nodeToRender = sceneLayer
        /// If set to true, we render at @1x resolution, instead of @2x or @3x
        let minimizePixels = false
        
        /// Get the CGRect from the crop shape, and  convert to scene space.
        /// We use `boundingBoxOfPath` and not `boundingBox`, because the latter would enclose the control points of a Bezier curve as well, which we safely avoid.
        guard let cropRect = cropShape.path?.boundingBoxOfPath else { return print("\(Self.self) - No Crop Region is Defined")}
        let cropInScene = nodeToRender.convert(cropRect, from: camera)
        
        /// Get the camera scale factor
        let cameraXScale = camera.xScale
        let cameraYScale = camera.yScale
        let inverseXScale = 1.0 / cameraXScale
        let inverseYScale = 1.0 / cameraYScale
        
        /// Get the screen pixel density
        /// We can use this technique to render the scene at less than native resolution in SpriteKit
        var screenScale: CGFloat
        if minimizePixels { screenScale = view.window?.screen.scale ?? 1.0 }
        else { screenScale = 1 }
        let screenScaleFactor = 1 / screenScale
        
        /// Scale the crop region accordingly
        let adjustedRegionInScene = CGRect(
            x: cropInScene.origin.x * inverseXScale * screenScaleFactor,
            y: cropInScene.origin.y * inverseYScale * screenScaleFactor,
            width: cropInScene.width * inverseXScale * screenScaleFactor,
            height: cropInScene.height * inverseYScale * screenScaleFactor
        )
        
        /// Save the original scale of the node to render, then scale it accordingly
        /// By scaling both the crop region and the node to render, we maintain a fixed size for the texture to render, which is a must
        let originalNodeToRenderXScale = nodeToRender.xScale
        let originalNodeToRenderYScale = nodeToRender.yScale
        nodeToRender.xScale = originalNodeToRenderXScale * inverseXScale * screenScaleFactor
        nodeToRender.yScale = originalNodeToRenderYScale * inverseYScale * screenScaleFactor
        
        /// Generate the snapshot
        if let texture = view.texture(from: nodeToRender, crop: adjustedRegionInScene) {
            //let filter = CIFilter.lineOverlay()
            /// Optional Core Image filter here, using `texture.applying(:)`
            snapshotContainer.texture = texture
            snapshotContainer.size = CGSize(width: texture.size().width * screenScale, height: texture.size().height * screenScale)
            
            /// Here we can pass the texture to a function that saves it to disk or some other processing on the background
        }
        
        /// Restore the original scene scale
        nodeToRender.xScale = originalNodeToRenderXScale
        nodeToRender.yScale = originalNodeToRenderYScale
    }
    
    // MARK: Update
    
    override func update(_ currentTime: TimeInterval) {
        currentSimulationTime = currentTime
        /// We start a frame cycle by showing the nodes we want to render, so that regular operations can be done
        sceneLayer.isHidden = false
        /// Hide the container that holds the rendered texture
        snapshotContainer.isHidden = true
        
        /// Change record button UI according to recording state
        if isSnapshotting {
            if let button = childNode(withName: "//*snapshot*") as? SKSpriteNode {
                button.color = .systemRed
            }
        } else {
            if let button = childNode(withName: "//*snapshot*") as? SKSpriteNode {
                button.color = .darkGray
            }
        }
        
        /// Camera inertia
        inertialCamera?.update()
        
        /// Camera Zoom Label
        if let label = childNode(withName: "//cameraZoomLabel") as? SKLabelNode, let camera = camera {
            let zoomPercentage = 100 / (camera.xScale)
            label.text = String(format: "%.0f%%", zoomPercentage)
        }
    }
    
    // MARK: Other SpriteKit Render Loop Callbacks
    /**
     
     For information, here are the other method executed by SpriteKit for each frame, in chronological order
     https://developer.apple.com/documentation/spritekit/skscenedelegate
     
     */
    override func didEvaluateActions() {
        
    }
    
    override func didSimulatePhysics() {
        
    }
    
    override func didApplyConstraints() {
        
    }
    
    // MARK: Update Finished
    
    override func didFinishUpdate() {
        /// This is the end of a frame cycle, just before rendering on the GPU.
        /// If the user has toggled snapshotting (recording), we call renderRegion() with some pre and post setup
        if isSnapshotting {
            /// Don't show the crop UI in the render
            cropShape.isHidden = true
            renderRegion()
            /// Show the container that holds the rendered snapshot
            snapshotContainer.isHidden = false
            /// Show the crop UI
            cropShape.isHidden = false
            /// Hide the layer we got the snapshot from in order to minimize rendering work
            sceneLayer.isHidden = true
        }
    }
    
    // MARK: Touch
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchedNodes = nodes(at: touch.location(in: self))
        
        inertialCamera?.touchesBegan()
        
        if let topNode = touchedNodes.max(by: { $0.zPosition > $1.zPosition }) {
            if topNode.name == "playpause" {
                isPaused.toggle()
                print("Paused: \(isPaused)")
            } else if topNode.name == "snapshot" {
                isSnapshotting.toggle()
                print("Snapshotting: \(isSnapshotting)")
            /// I use buttonA to understand the behavior of speed, isPaused ofr physicsWorld, physics fields, and particles.
            } else if topNode.name == "buttonA" {
                enumerateChildNodes(withName: "//videoNode", using: { node, stpp in
                    if let videoNode = node as? SKVideoNode {
                        videoNode.play()
                    }
                })
            } else if topNode.name == "buttonB" {
                enumerateChildNodes(withName: "//videoNode", using: { node, stpp in
                    if let videoNode = node as? SKVideoNode {
                        videoNode.pause()
                    }
                })
            }
        }
    }
}
