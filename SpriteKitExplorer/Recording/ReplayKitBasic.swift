/**
 
 # Replay Kit
 
 A basic setup that demonstrates the use of ReplayKit to record a screen with a SpriteKit view.
 
 https://support.apple.com/en-ph/guide/security/seca5fc039dd/web
 
 Achraf Kassioui
 Created 2 December 2024
 Updated 3 December 2024
 
 */

import SwiftUI
import SpriteKit
import AVFoundation
import ReplayKit

struct ReplayKitBasicView: View {
    @State private var sceneID = UUID()
    var body: some View {
        VStack {
            SpriteView(
                scene: ReplayKitBasicScene(),
                options: [.shouldCullNonVisibleNodes]
                ,debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount, .showsQuadCount]
            )
            .id(sceneID)
            .onAppear { sceneID = UUID() }
            .background(Color(SKColor.black))
            .persistentSystemOverlays(.hidden)
            
            Spacer()
        }
    }
}

#Preview {
    ReplayKitBasicView()
}

/// Add the ReplayKit Preview Controller Protocol here
class ReplayKitBasicScene: SKScene, RPPreviewViewControllerDelegate {
    
    // MARK: Properties
    
    var inertialCamera: InertialCamera?
    
    let uiLayer = SKNode()
    let sceneLayer = SKNode()
    
    var isRecording: Bool = false
    
    // MARK: Scene Setup
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        
        createCamera()
        createLayers()
        
        createSomeNodes(parent: sceneLayer, view: view)
        
        createPlayPauseButton(parent: uiLayer, view: view)
        createSnapshotButton(parent: uiLayer, view: view)
        createCameraZoomLabel(parent: uiLayer, view: view)
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
    
    // MARK: UI
    
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
        button.name = "record"
        button.colorBlendFactor = 1
        button.color = .darkGray
        if let texture = view.texture(from: shape) {
            button.texture = texture
            button.size = texture.size()
            button.position = CGPoint(x: -80, y: -340)
            parent.addChild(button)
        }
        
        let icon = SKSpriteNode(texture: SKTexture(imageNamed: "record-icon"), color: .white, size: CGSize(width: 24, height: 24))
        icon.name = "record"
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
    
    // MARK: ReplayKit Basic
    /**
     
     This is the main ReplayKit function.
     It's called from wherever we want to start/stop recording, for example, a SpriteKit button.
     
     The function toggles a user-defined state variable `isRecording`, which we use to update the state of the UI in SpriteKit.
     This boolean isn't part of ReplayKit itself.
     
     If a recording is stopped and completed successfully, ReplayKit shows its (horrendous) preview sheet.
     
     */
    func toggleRecording() {
        let recorder = RPScreenRecorder.shared()
        
        if isRecording {
            recorder.stopRecording { [weak self] previewController, error in
                self?.isRecording = false
                if let error = error {
                    print("Error stopping recording: \(error.localizedDescription)")
                } else if let previewController = previewController {
                    self?.view?.window?.rootViewController?.present(previewController, animated: true)
                }
            }
        } else {
            recorder.startRecording { [weak self] error in
                if let error = error {
                    print("Error starting recording: \(error.localizedDescription)")
                } else {
                    self?.isRecording = true
                }
            }
        }
    }
    
    /// If I don't add this, I can't dismiss the recording video sheet that appears after the recording has been completed.
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.dismiss(animated: true)
    }
    
    // MARK: Update
    
    override func update(_ currentTime: TimeInterval) {
        /// Change record button UI according to recording state
        if isRecording {
            if let button = childNode(withName: "//record") as? SKSpriteNode {
                button.color = .systemRed
            }
        } else {
            if let button = childNode(withName: "//record") as? SKSpriteNode {
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
    
    // MARK: Touch
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchedNodes = nodes(at: touch.location(in: self))
        
        inertialCamera?.touchesBegan()
        
        if let topNode = touchedNodes.max(by: { $0.zPosition > $1.zPosition }) {
            if topNode.name == "playpause" {
                isPaused.toggle()
            } else if topNode.name == "record" {
                toggleRecording()
                print("isRecording: \(isRecording)")
            }
        }
    }
}
