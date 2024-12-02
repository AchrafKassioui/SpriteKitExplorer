/**
 
 # Render to Texture
 
 This setup uses SKView `view.texture(from:crop)` to render a node tree.
 A function using UIKit drawHierarchy is included to compare performance. `view.texture(from:)` is faster than `drawHierarchy(in:afterScreenUpdates:)`
 
 There is a SnapshotManager class that handles the snapshotting.
 
 Achraf Kassioui
 Created 24 November 2024
 Updated 29 November 2024
 
 */

import SwiftUI
import SpriteKit
import Photos

struct RenderToTextureView: View {
    @State private var sceneID = UUID()
    var body: some View {
        SpriteView(
            scene: RenderToTextureScene(),
            options: [.shouldCullNonVisibleNodes],
            debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount, .showsQuadCount]
        )
        .id(sceneID)
        .onAppear { sceneID = UUID() }
        //.ignoresSafeArea()
        .background(Color(SKColor.black))
        .persistentSystemOverlays(.hidden)
    }
}

#Preview {
    RenderToTextureView()
}

class RenderToTextureScene: SKScene {
    
    // MARK: Properties
    
    var inertialCamera: InertialCamera?

    let uiLayer = SKNode()
    let sceneLayer = SKNode()
    
    fileprivate var snapshotManager: SnapshotManager?
    let snapshotContainer = SKSpriteNode()
    
    // MARK: Scene Setup
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        
        createCamera()
        createLayers()
        createSnapshotContainer(parent: self, view: view)
        
        createSomeNodes(parent: sceneLayer)
        createPlayPauseButton(parent: uiLayer, view: view)
        createSnapshotButton(parent: uiLayer, view: view)
        createExportNotification(parent: uiLayer, view: view)
        
        snapshotManager = SnapshotManager(view: view, nodeToSnapshot: sceneLayer, snapshotContainer: snapshotContainer)
        snapshotManager?.onExportCompletion = { [weak self] in
            self?.showExportNotification()
        }
    }
    
    func createCamera() {
        inertialCamera = InertialCamera(scene: self)
        camera = inertialCamera
        inertialCamera?.zPosition = 1000
        if let inertialCamera = inertialCamera { addChild(inertialCamera) }
    }
    
    func createLayers() {
        guard let camera = camera else { return }
        uiLayer.zPosition = 100
        camera.addChild(uiLayer)
        addChild(sceneLayer)
    }
    
    // MARK: Snapshot Container
    
    func createSnapshotContainer(parent: SKNode, view: SKView) {
        snapshotContainer.position = position
        snapshotContainer.zPosition = 11
        parent.addChild(snapshotContainer)
    }
    
    // MARK: UI
    
    func showExportNotification() {
        guard let node = childNode(withName: "//notificationOverlay") else { return }
        let action = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.wait(forDuration: 3),
            SKAction.fadeOut(withDuration: 0.1)
        ])
        action.timingMode = .easeInEaseOut
        node.removeAllActions()
        node.run(action)
    }
    
    func createExportNotification(parent: SKNode, view: SKView) {
        let shape = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 12)
        shape.lineWidth = 1
        shape.strokeColor = SKColor(white: 0, alpha: 0.6)
        shape.fillColor = .white
        
        let overlay = SKSpriteNode()
        overlay.name = "notificationOverlay"
        overlay.colorBlendFactor = 1
        overlay.color = .darkGray
        if let texture = view.texture(from: shape) {
            overlay.texture = texture
            overlay.size = texture.size()
            //overlay.position = CGPoint(x: 0, y: view.bounds.height/2 - view.safeAreaInsets.top - overlay.size.height/2 - 10)
            overlay.alpha = 0
            parent.addChild(overlay)
        }
        
        let label = SKLabelNode(text: "Export Complete")
        label.fontName = "Menlo-Bold"
        label.fontSize = 17
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -2)
        overlay.addChild(label)
    }
    
    func createPlayPauseButton(parent: SKNode, view: SKView) {
        let shape = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 18)
        shape.lineWidth = 1
        shape.strokeColor = SKColor(white: 0, alpha: 0.6)
        shape.fillColor = .white
        
        let button = SKSpriteNode()
        button.name = "playpause"
        button.colorBlendFactor = 1
        button.color = .darkGray
        if let texture = view.texture(from: shape) {
            button.texture = texture
            button.size = texture.size()
            button.position = CGPoint(x: 0, y: -330)
            parent.addChild(button)
        }
        
        let icon = SKSpriteNode(texture: SKTexture(imageNamed: "play-pause-icon"), color: .white, size: CGSize(width: 24, height: 24))
        icon.name = "playpause"
        button.addChild(icon)
    }
    
    func createSnapshotButton(parent: SKNode, view: SKView) {
        let shape = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 18)
        shape.lineWidth = 1
        shape.strokeColor = SKColor(white: 0, alpha: 0.6)
        shape.fillColor = .white
        
        let button = SKSpriteNode()
        button.name = "snapshot"
        button.colorBlendFactor = 1
        button.color = .darkGray
        if let texture = view.texture(from: shape) {
            button.texture = texture
            button.size = texture.size()
            button.position = CGPoint(x: 70, y: -330)
            parent.addChild(button)
        }
        
        let icon = SKSpriteNode(texture: SKTexture(imageNamed: "record-icon"), color: .white, size: CGSize(width: 24, height: 24))
        icon.name = "snapshot"
        button.addChild(icon)
    }
    
    // MARK: Create some Nodes
    
    func createSomeNodes(parent: SKNode) {
        physicsWorld.gravity = CGVector(dx: 0, dy: -10)
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        let background = SKSpriteNode(color: scene!.backgroundColor, size: view!.bounds.size)
        parent.addChild(background)
        
        let shapeRadius: CGFloat = 10
        let xRange = SKRange(lowerLimit: frame.minX + shapeRadius, upperLimit: frame.maxX - shapeRadius)
        let yRange = SKRange(lowerLimit: frame.minY + shapeRadius, upperLimit: frame.maxY - shapeRadius)
        let lockInsideFrame = SKConstraint.positionX(xRange, y: yRange)
        
        let shape = SKShapeNode(circleOfRadius: shapeRadius)
        shape.fillColor = .systemYellow
        shape.lineWidth = 1
        shape.strokeColor = .black
        guard let view = view else { return }
        let texture = view.texture(from: shape)
        
        //let heavierTexture = SKTexture(imageNamed: "smoke_128*128")
        
        for i in 1...700 {
            let sprite = SKSpriteNode(texture: texture)
            sprite.name = "NaNCandidate"
            sprite.physicsBody = SKPhysicsBody(circleOfRadius: shapeRadius)
            sprite.physicsBody?.charge = -0.1
            sprite.constraints = [lockInsideFrame]
            
            run(SKAction.wait(forDuration: Double(i) * 0.01)) {
               parent.addChild(sprite)
            }
        }
        
        let eField = SKFieldNode.electricField()
        eField.position = CGPoint(x: -1, y: -1)
        eField.minimumRadius = 50
        eField.strength = 1
        parent.addChild(eField)
        
        let mField = SKFieldNode.noiseField(withSmoothness: 1, animationSpeed: 1)
        mField.position = CGPoint(x: 1, y: 1)
        mField.minimumRadius = 150
        mField.strength = 10
        parent.addChild(mField)
        
        if let emitter = SKEmitterNode(fileNamed: "FireLarge") {
            emitter.fieldBitMask = 1
            //emitter.particleBirthRate = 50000
            emitter.targetNode = parent
            parent.addChild(emitter)
        }
    }
    
    // MARK: Texture From View
    /**
     
     This is a standalone function using `view.texture(from:crop:)`
     https://developer.apple.com/documentation/spritekit/skview/1519994-texture
     I use this function for testing. There is a more integrating SnapshotManager class down below.
     
     */
    func captureWithSKView() {
        guard let view = view else { return }
        
        /// The factor by which the captured node tree will be scaled down
        /// We do this to minimize the work the GPU has to do to generate the texture on the separate pass
        /// Here we choose to render the texture at @1x resolution, instead of the @2x or @3x resolutions of Apple devices.
        let retinaScale = view.window?.screen.scale ?? 1.0
        let scaleFactor = 1 / retinaScale
        
        /// Scale the node tree
        let originalXScale = sceneLayer.xScale
        let originalYScale = sceneLayer.yScale
        sceneLayer.xScale = originalXScale * scaleFactor
        sceneLayer.yScale = originalYScale * scaleFactor
        
        /// Adjust the crop rectangle to account for the scaling
        let cropRect = CGRect(origin: CGPoint(x: -view.bounds.width / 2 * scaleFactor, y: -view.bounds.height / 2 * scaleFactor),
                              size: CGSize(width: view.bounds.width * scaleFactor, height: view.bounds.height * scaleFactor)
        )
        
        if let texture = view.texture(from: sceneLayer, crop: cropRect) {
            snapshotContainer.texture = texture
            snapshotContainer.size = texture.size()
        }
        
        /// Restore original scale
        sceneLayer.xScale = originalXScale
        sceneLayer.yScale = originalYScale
    }
    
    // MARK: UIKit DrawHierarchy
    /**
     
     This is a standalone function using `view.drawHierarchy(in:afterScreenUpdates:)`
     https://developer.apple.com/documentation/uikit/uiview/1622589-drawhierarchy
     I use this function for testing. I find it slower than `view.texture(from:crop:)`
     
     */
    func captureWithDrawHierarchy() {
        guard let view = view else { return }
        
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        print(image)
        //saveImageToDisk(image)
    }
    
    // MARK: Update
    
    override func update(_ currentTime: TimeInterval) {
        snapshotManager?.update()
        
        /// Change record button UI according to recording state
        if snapshotManager?.isSnapshotting ?? false {
            if let button = childNode(withName: "//*snapshot*") as? SKSpriteNode {
                button.color = .red
            }
        } else {
            if let button = childNode(withName: "//*snapshot*") as? SKSpriteNode {
                button.color = .darkGray
            }
        }
        
        /// Camera inertia
        inertialCamera?.update()
        
        /// In some extreme cases, a physics simulation would make a node disappear from the scene. Even constraints wouldn't hold it in.
        /// Logging the disappearing node position returns a NaN value.
        /// This enumeration checks if the position is NaN, and brings back the node into view.
        enumerateChildNodes(withName: "//*NaNCandidate*", using: { node, stop in
            if node.position.x.isNaN || node.position.y.isNaN {
                print("position is absurd")
                node.physicsBody?.velocity = .zero
                node.physicsBody?.angularVelocity = 0
                node.position = CGPoint(x: 100, y: 100)
            }
        })
    }
    
    // MARK: Update Finished
    
    override func didFinishUpdate() {
        snapshotManager?.didFinishUpdate()
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
                snapshotManager?.isSnapshotting.toggle()
            }
        }
    }
}

// MARK: Snapshot Manager
/**
 
 A first version of a class to start and stop snapshots in a SpriteKit scene.
 The start and stop function are currently broken. Use update and didFinishUpdate instead
 
 */

fileprivate class SnapshotManager {
    weak var view: SKView?
    weak var nodeToSnapshot: SKNode?
    weak var snapshotContainer: SKSpriteNode?
    
    var isSnapshotting = false
    var onExportCompletion: (() -> Void)?
    private(set) var framesToExport: Int = 0
    private(set) var isExporting = false
    private var exportedFrames: Int = 0
    
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    init(view: SKView, nodeToSnapshot: SKNode, snapshotContainer: SKSpriteNode) {
        self.view = view
        self.nodeToSnapshot = nodeToSnapshot
        self.snapshotContainer = snapshotContainer
    }
    
    func start() {
        guard !isSnapshotting else {
            print("SnapshotManager: Cannot start capturing while already capturing.")
            return
        }
        guard !isExporting else {
            print("SnapshotManager: Cannot start capturing while exporting.")
            return
        }
        
        framesToExport = 0
        exportedFrames = 0
        isSnapshotting = true
        print("SnapshotManager: Capture started.")
    }
    
    func stop() {
        guard isSnapshotting else {
            print("SnapshotManager: Cannot stop capturing; no capture is ongoing.")
            return
        }
        isSnapshotting = false
        print("SnapshotManager: Capture stopped with \(framesToExport) frames left to export.")
        if framesToExport > 0 {
            isExporting = true
        }
    }
    
    // MARK: Update
    
    func update() {
        nodeToSnapshot?.alpha = 1
        snapshotContainer?.alpha = 0
    }
    
    // MARK: Update Finished
    
    func didFinishUpdate() {
        if isSnapshotting {
            renderToTexture()
            snapshotContainer?.alpha = 1
            nodeToSnapshot?.alpha = 0
        }
    }
    
    // MARK: Render Texture
    
    func renderToTexture() {
        guard isSnapshotting, let view = view, let nodeToSnapshot = nodeToSnapshot, let snapshotContainer = snapshotContainer else { return }
        
        framesToExport += 1
        
        /// The factor by which the captured node tree will be scaled down
        let retinaScale = view.window?.screen.scale ?? 1.0
        let scaleFactor = 1 / retinaScale
        
        /// Scale the node tree
        let originalXScale = nodeToSnapshot.xScale
        let originalYScale = nodeToSnapshot.yScale
        nodeToSnapshot.xScale = originalXScale * scaleFactor
        nodeToSnapshot.yScale = originalYScale * scaleFactor
        
        /// Adjust the crop rectangle to account for the scaling
        let cropRect = CGRect(
            origin: CGPoint(x: -view.bounds.width / 2 * scaleFactor, y: -view.bounds.height / 2 * scaleFactor),
            size: CGSize(width: view.bounds.width * scaleFactor, height: view.bounds.height * scaleFactor)
        )
        
        /// Generate texture
        if let texture = view.texture(from: nodeToSnapshot, crop: cropRect) {
            snapshotContainer.texture = texture
            snapshotContainer.size = texture.size()
            
            /// Save to disk
            //saveTextureToPhotoLibrary(texture: texture)
        }
        
        /// Restore original scale
        nodeToSnapshot.xScale = originalXScale
        nodeToSnapshot.yScale = originalYScale
    }
    
    // MARK: Save to Photos
    
    /// Save the images to the Photo Galery
    private func saveTextureToPhotoLibrary(texture: SKTexture) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            /// Convert SKTexture to UIImage
            let cgImage = texture.cgImage()
            let uiImage = UIImage(cgImage: cgImage)
            
            /// Save the image to the Photos app
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    print("SnapshotManager: Permission to access the photo library was denied.")
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
                }) { success, error in
                    if success {
                        print("SnapshotManager: Snapshot saved to the Photos app.")
                    } else if let error = error {
                        print("SnapshotManager: Failed to save snapshot to the Photos app: \(error)")
                    }
                    
                    /// Update exported frames on the main thread
                    DispatchQueue.main.async {
                        self.exportedFrames += 1
                        if self.exportedFrames == self.framesToExport {
                            self.isExporting = false
                            print("SnapshotManager: Export complete.")
                            self.onExportCompletion?()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Save to Disk
    
    /// Save the images in the sandboxed simulator folders
    private func saveTextureToDisk(texture: SKTexture) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let cgImage = texture.cgImage()
            let uiImage = UIImage(cgImage: cgImage)
            if let pngData = uiImage.pngData() {
                let fileManager = FileManager.default
                let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsURL.appendingPathComponent("CaptureManager_snapshot_\(UUID().uuidString).png")
                
                do {
                    try pngData.write(to: fileURL)
                    print("Saved snapshot to disk: \(fileURL)")
                } catch {
                    print("Failed to save snapshot: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.exportedFrames += 1
                if self.exportedFrames == self.framesToExport {
                    self.isExporting = false
                    print("SnapshotManager: Export complete.")
                    self.onExportCompletion?()
                }
            }
        }
    }
}
