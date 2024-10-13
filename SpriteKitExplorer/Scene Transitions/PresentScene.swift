/**
 
 # Present Scene
 
 A SpriteKit scene switcher using SwiftUI.
 
 Created: 13 October 2024
 Updated: 13 October 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct SpriteKitView: View {
    var scene: SKScene
    var isPaused = false
    @State private var sceneId = UUID()
    
    var body: some View {
        SpriteView(scene: scene, isPaused: isPaused)
            .id(sceneId)
            .onAppear { sceneId = UUID() }
            .ignoresSafeArea()
    }
}

struct PresentSceneView: View {
    @State private var selectedScene = 1
    
    var body: some View {
        ZStack {
            if selectedScene == 1 {
                SpriteKitView(scene: PresentSceneScene())
            } else if selectedScene == 2 {
                SpriteKitView(scene: CameraDemoScene())
            }
            
            VStack {
                Picker("Select a Scene", selection: $selectedScene) {
                    Text("Track Scene").tag(1)
                    Text("Camera Playground").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                Spacer()
            }
        }
    }
}

#Preview {
    PresentSceneView()
}

// MARK: - SpriteKit

class PresentSceneScene: SKScene {
    
    // MARK: didMove
    override func didMove(to view: SKView) {
        size = view.bounds.size
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        view.isMultipleTouchEnabled = true
        scaleMode = .resizeFill
        backgroundColor = .lightGray
        
        runAroundTrack()
    }
    
    // MARK: Create action
    func runAroundTrack() {
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: -115, y: 13))
        bezierPath.addCurve(to: CGPoint(x: -82, y: 91), controlPoint1: CGPoint(x: -154, y: 35), controlPoint2: CGPoint(x: -115, y: 64))
        bezierPath.addCurve(to: CGPoint(x: 2, y: 70), controlPoint1: CGPoint(x: -50, y: 118), controlPoint2: CGPoint(x: -37, y: 67))
        bezierPath.addCurve(to: CGPoint(x: 124, y: 91), controlPoint1: CGPoint(x: 40, y: 74), controlPoint2: CGPoint(x: 105, y: 121))
        bezierPath.addCurve(to: CGPoint(x: 40, y: -82), controlPoint1: CGPoint(x: 144, y: 61), controlPoint2: CGPoint(x: 92, y: -59))
        bezierPath.addCurve(to: CGPoint(x: -115, y: 13), controlPoint1: CGPoint(x: -11, y: -105), controlPoint2: CGPoint(x: -76, y: -10))
        
        let shape = SKShapeNode(path: bezierPath.cgPath)
        shape.name = "shape"
        shape.lineWidth = 30
        shape.strokeColor = .darkGray
        shape.position = .zero
        addChild(shape)
        
        let sprite = SKSpriteNode(color: .systemYellow, size: CGSize(width: 20, height: 60))
        let action = SKAction.follow(bezierPath.cgPath, asOffset: false, orientToPath: true, speed: 200)
        sprite.run(SKAction.repeatForever(action))
        addChild(sprite)
    }
}
