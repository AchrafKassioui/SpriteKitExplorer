/**
 
 # Preferred Frames Per Second
 
 `SKView` has a `preferredFramesPerSecond` property that can be changed programmatically.
 The property can be set from 1 to 120 fps. However, that actual framerate will be automatically set by SpriteKit to match the closest supported screen refresh rate.
 
 Created: 10 October 2024
 Updated: 13 October 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct PreferredFPSView: View {
    @State private var sceneId = UUID()
    @State private var frameRate: Double = 20
    
    var myScene = PreferredFPSScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                preferredFramesPerSecond: Int(frameRate),
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsFPS, .showsDrawCount]
            )
            .id(sceneId)
            .onAppear {
                sceneId = UUID()
            }
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                HStack {
                    Slider(
                        value: $frameRate,
                        in: 1...60,
                        step: 1
                    )
                    .frame(maxWidth: 200)
                    .onChange(of: frameRate) {
                        myScene.changeFrameRate(to: Int(frameRate))
                    }
                    
                    Text("\(Int(frameRate)) FPS")
                }
            }
        }
    }
}

#Preview {
    PreferredFPSView()
}

// MARK: - SpriteKit

class PreferredFPSScene: SKScene {
    
    // MARK: didMove
    override func didMove(to view: SKView) {
        size = view.bounds.size
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        view.isMultipleTouchEnabled = true
        scaleMode = .resizeFill
        backgroundColor = .lightGray
        
        runAroundTrack()
    }
    
    // MARK: Frame rate
    func changeFrameRate(to frameRate: Int) {
        guard let view = self.view else {
            print("Not SKView found")
            return
        }
        
        view.preferredFramesPerSecond = frameRate
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
