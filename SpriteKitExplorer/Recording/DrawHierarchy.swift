/**
 
 # UIKit drawHierarchy
 
 This setup uses UIKit `drawHierarchy` to record the SpriteKit view and save it to disk as a sequence of images.
 https://developer.apple.com/documentation/uikit/uiview/1622589-drawhierarchy
 
 Achraf Kassioui
 Created 22 November 2024
 Updated 29 November 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

struct DrawHierarchyView: View {
    let myScene = DrawHierarchyScene()
    var recorder = FrameRecorder()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene
                ,debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount, .showsQuadCount]
            )
            .ignoresSafeArea()
            VStack {
                Spacer()
                HStack {
                    SWUIScenePauseButton(scene: myScene, isPaused: false)
                    Button {
                        if let view = myScene.view {
                            recorder.isRecording ? recorder.stopRecording() : recorder.startRecording(view: view)
                        }
                    } label: {
                        Image(systemName: recorder.isRecording ? "stop.fill" : "record.circle.fill")
                    }
                    .buttonStyle(roundButtonStyleWithStandardBehavior())
                }
            }
        }
        .background(Color(SKColor.black))
        .persistentSystemOverlays(.hidden)
    }
}

#Preview {
    DrawHierarchyView()
}

// MARK: Frame Recorder

/// Observation allows to react to changes of properties in SwiftUI
/// We listen to `isRecording` to change the UI
@Observable class FrameRecorder {
    var isRecording = false
    
    private var timer: Timer?
    private var frameIndex = 0
    private let saveQueue = DispatchQueue(label: "frame-save-queue")
    
    /// Start recording frames
    /// By default we record 1 second of 60 frames per second
    func startRecording(view: SKView, duration: TimeInterval = 1.0, frameRate: Int = 60) {
        guard !isRecording else { return }
        isRecording = true
        frameIndex = 0
        
        let interval = 1.0 / Double(frameRate)
        let totalFrames = Int(duration * Double(frameRate))
        var capturedFrames = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if capturedFrames >= totalFrames {
                self.stopRecording()
                return
            }
            
            self.captureFrame(from: view)
            capturedFrames += 1
        }
    }
    
    /// Capture a single frame and save it to disk
    /// Using UIKit `view.drawHierarchy`
    private func captureFrame(from view: SKView) {
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let image = renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        }
        
        saveFrameToDisk(image: image)
    }
    
    /// Save a frame to disk
    private func saveFrameToDisk(image: UIImage) {
        saveQueue.async {
            guard let data = image.pngData() else { return }
            /// The images are saved in the documents folder of the simulator sandbox
            /// Example of a path:
            ///  /Users/[username]]/Library/Developer/Xcode/UserData/Previews/Simulator Devices/[UUID]]/data/Containers/Data/Application/[UUID]/Documents
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileName = "spritekit_frame_\(self.frameIndex).png"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            do {
                try data.write(to: fileURL)
                print("Saved: \(fileName)")
                self.frameIndex += 1
            } catch {
                print("Error saving frame: \(error)")
            }
        }
    }
    
    /// Stop recording frames
    func stopRecording() {
        timer?.invalidate()
        timer = nil
        isRecording = false
        print("Recording stopped.")
    }
}

// MARK: Scene Setup

class DrawHierarchyScene: SKScene {
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        
        animateSomething(view: view)
    }
    
    // MARK: Animate Something
    
    func animateSomething(view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        let perimeterRadius: CGFloat = 190
        let perimeter = SKShapeNode(circleOfRadius: perimeterRadius)
        perimeter.lineWidth = 6
        perimeter.strokeColor = SKColor(white: 0, alpha: 0)
        perimeter.fillColor = SKColor(white: 1, alpha: 0)
        perimeter.physicsBody = SKPhysicsBody(edgeLoopFrom: perimeter.path!)
        addChild(perimeter)
        
        let shapeRadius: CGFloat = 10
        let shape = SKShapeNode(circleOfRadius: shapeRadius)
        shape.lineWidth = 1
        shape.strokeColor = SKColor.black
        shape.fillColor = .systemYellow
                
        guard let texture = view.texture(from: shape) else { return }

        let lockInsidePerimeter = SKConstraint.distance(SKRange(upperLimit: perimeterRadius - shapeRadius), to: .zero)
        
        for i in 1...10 {
            let sprite = DraggableSpriteWithVelocity(texture: texture, color: .clear, size: texture.size())
            sprite.name = "DraggableSpriteWithPhysics NaNCandidate"
            sprite.physicsBody = SKPhysicsBody(circleOfRadius: shapeRadius)
            sprite.physicsBody?.charge = -1
            sprite.physicsBody?.density = 0.1
            sprite.zPosition = 2
            sprite.constraints = [lockInsidePerimeter]
            
            run(SKAction.wait(forDuration: Double(i) * 0.01)) {
                self.addChild(sprite)
            }
            
            if let emitter = SKEmitterNode(fileNamed: "Tracer") {
                emitter.zPosition = 1
                sprite.addChild(emitter)
                emitter.targetNode = self
            }
        }
        
        let falloff: Float = 0
        let safePosition = CGPoint(x: -1, y: -1)
        
        let eField = SKFieldNode.electricField()
        eField.position = safePosition
        eField.minimumRadius = 100
        eField.falloff = falloff
        eField.strength = 5
        addChild(eField)
        
        let mField = SKFieldNode.magneticField()
        mField.position = safePosition
        mField.minimumRadius = 100
        mField.strength = 0.1
        addChild(mField)
    }
    
    // MARK: Update
    
    override func update(_ currentTime: TimeInterval) {
        enumerateChildNodes(withName: "//*DraggableSpriteWithPhysics*", using: { node, _ in
            if let sprite = node as? DraggableSpriteWithVelocity {
                sprite.update(currentTime: currentTime)
            }
        })
    }
}
