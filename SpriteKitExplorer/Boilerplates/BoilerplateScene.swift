/**
 
 # SpriteKit Boilerplate
 
 Achraf Kassioui
 Created 15 November 2024
 Updated 15 November 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

struct SWUIScenePauseButton: View {
    let scene: SKScene
    @State var isPaused: Bool
    
    var body: some View {
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
        .foregroundStyle(.black)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPaused.toggle()
                    scene.isPaused = isPaused
                }
        )
    }
}

/// The main SwiftUI view
struct BoilerplateView: View {
    let myScene = BoilerplateScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene
                ,debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount, .showsQuadCount]
            )
            .ignoresSafeArea()
            VStack {
                Spacer()
                SWUIScenePauseButton(scene: myScene, isPaused: false)
            }
        }
        .background(Color(SKColor.black))
        .persistentSystemOverlays(.hidden)
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
