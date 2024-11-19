/**
 
 # SpriteKit Boilerplate
 
 Achraf Kassioui
 Created 15 November 2024
 Updated 15 November 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

/// A SwiftUI button component. An instance of the SpriteKit scene must be passed to it.
/// Todo: Make the button trigger on touchesBegan, not touchesEnded
struct SWUIRoundButton: View {
    let scene: SKScene
    @State private var isPaused: Bool = false
    var body: some View {
        Button(action: {
            scene.isPaused.toggle()
            isPaused = scene.isPaused
        }) {
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.2), lineWidth: 2)
                    .frame(width: 60, height: 60)
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 24))
                    .frame(width: 60, height: 60)
                    .background(.white.opacity(0.1))
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .foregroundStyle(.black)
    }
}

/// The main SwiftUI view
struct BoilerplateView: View {
    var myScene = BoilerplateScene()
    @State private var isPaused: Bool = false
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount, .showsQuadCount]
            )
            VStack {
                Spacer()
                SWUIRoundButton(scene: myScene)
            }
            .padding(20)
        }
        .background(Color(SKColor.black))
    }
}

#Preview {
    BoilerplateView()
}

class BoilerplateScene: SKScene {
    
    // MARK: Scene Setup
    
    private var lastUpdateTime: TimeInterval = 0
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
    }
    
    // MARK: Update
    
    override func update(_ currentTime: TimeInterval) {
        /// Calculate the time change since the previous update.
        let deltaTime = currentTime - lastUpdateTime
        if deltaTime > 0.017 {
            print(deltaTime)
        }
        
        /// Set previousUpdateTime to the current time, so the next update has accurate information.
        lastUpdateTime = currentTime
    }
    
    // MARK: Touch
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
