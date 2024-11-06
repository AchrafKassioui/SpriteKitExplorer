/**
 
 # Haptic Playground
 
 Achraf Kassioui
 Created: 22 October 2024
 Updated: 22 October 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - Live preview

struct HapticPlaygroundView: View {
    var myScene = HapticPlaygroundScene()
    @State private var isPaused = false
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                preferredFramesPerSecond: 120,
                options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
                debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS]
            )
            .ignoresSafeArea()
            .background(.black)
            
//            VStack {
//                Spacer()
//                Button(action: {
//                    myScene.isPaused.toggle()
//                    isPaused = myScene.isPaused
//                }) {
//                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
//                }
//                .buttonStyle(squareButtonStyle())
//            }
        }
    }
}

#Preview {
    HapticPlaygroundView()
}

// MARK: - Scene Setup

class HapticPlaygroundScene: SKScene {
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = SKColor.gray
        view.isMultipleTouchEnabled = true
        view.contentMode = .center
        
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.lock = false
        inertialCamera.zPosition = 1000
        camera = inertialCamera
        addChild(inertialCamera)
        
        Task {
            let gridImage = await generateGridTexture(cellSize: 50, rows: 20, cols: 10, linesColor: UIColor(white: 1, alpha: 0.3))
            
            await MainActor.run {
                let backgroundSprite = SKSpriteNode(texture: SKTexture(image: gridImage))
                addChild(backgroundSprite)
            }
        }
        
        let label = SKLabelNode(text: "❤️")
        label.name = "label"
        label.fontSize = 92
        label.verticalAlignmentMode = .center
        label.zPosition = 2
        addChild(label)
        
        haptic.prepare()
        createBaseUI(view: view)
    }
    
    func createBaseUI(view: SKView) {
        guard let camera = camera else { return }
        let button = ButtonWithIconAndPattern(
            size: CGSize(width: 50, height: 50),
            icon1: "pause-icon",
            icon2: "play-icon",
            iconSize: CGSize(width: 32, height: 32),
            onTouch: {
                self.isPaused.toggle()
            }
        )
        button.position.y = -view.bounds.height/2 + view.safeAreaInsets.bottom + button.frame.height/2
        button.blendMode = .multiplyAlpha
        camera.addChild(button)
    }
    
    // MARK: Helpers
    
    func pulseNode(node: SKNode) {
        let action1 = SKAction.scale(to: 1.3, duration: 0.07)
        action1.timingMode = .easeInEaseOut
        let action2 = SKAction.scale(to: 1, duration: 0.15)
        action2.timingMode = .easeInEaseOut
        node.run(SKAction.sequence([action1, action2]))
    }
    
    // MARK: Haptic Feedback
    
    var haptic = UIImpactFeedbackGenerator()
    
    func generateHpaticFeedback() {
        haptic.impactOccurred(intensity: 1)
    }
    
    // MARK: Update
    /**
     
     Time tracking variables.
     
     */
    var lastUpdateTime: TimeInterval = 0
    var timeSinceLastCall: TimeInterval = 0
    
    func doActionEachInterval(currentTime: TimeInterval, interval: TimeInterval, action: () -> Void) {
        /// Calculate time passed since the last update
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        /// Accumulate time
        timeSinceLastCall += deltaTime
        
        /// Check if it's time to call the function
        if timeSinceLastCall >= interval {
            action()
            
            /// Reset the time tracker
            timeSinceLastCall = 0
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let inerterialCamera = camera as? InertialCamera {
            inerterialCamera.updateInertia()
        }
        
        doActionEachInterval(currentTime: currentTime, interval: 0.3) {
            generateHpaticFeedback()
            if let node = childNode(withName: "//label") {
                pulseNode(node: node)
            }
        }
    }
    
    // MARK: Touch Events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            if let inerterialCamera = camera as? InertialCamera {
                inerterialCamera.stopInertia()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch.location(in: self) == .zero {
                generateHpaticFeedback()
            }
        }
    }
    
}
