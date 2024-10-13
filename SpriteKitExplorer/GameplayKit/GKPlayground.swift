/**
 
 # GameplayKit playground
 
 Experimenting with GameplayKit
 
 Created: 19 March 2024
 
 */

import SwiftUI
import SpriteKit
import GameplayKit

struct GKPlaygroundView: View {
    var myScene = GKPlaygroundScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS]
            )
            .ignoresSafeArea()
            
            
        }
    }
}

#Preview {
    GKPlaygroundView()
}

class GKPlaygroundScene: SKScene {
    
    var label = SKLabelNode()
    
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .gray
        setupCamera()
        setupLabel()
    }
    
    func setupCamera() {
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.lockRotation = true
        camera = inertialCamera
        addChild(inertialCamera)
    }
    
    func setupLabel() {
        label.text = ""
        label.fontName = "Menlo-Bold"
        label.fontSize = 32
        label.zPosition = 1
        addChild(label)
    }
    
    // MARK: GameplayKit functions
    
    func nonClusteredRandomValues() {
        /// consecutive values are never the same
        /// source: https://devstreaming-cdn.apple.com/videos/wwdc/2015/608rpwq1ltvg5nmk/608/608_hd_introducing_gameplaykit.mp4
        let dice = GKShuffledDistribution(forDieWithSideCount: 10)
        let choice = dice.nextInt()
        label.text = String(describing: choice)
    }
    
    func customDice() {
        let customDice = GKRandomDistribution(lowestValue: 1, highestValue: 10)
        let choice = customDice.nextInt()
        label.text = String(describing: choice)
    }
    
    func throwDice20() {
        let d20 = GKRandomDistribution.d20()
        let choice = d20.nextInt()
        label.text = String(describing: choice)
    }
    
    func throwDice6() {
        let d6 = GKRandomDistribution.d6()
        let choice = d6.nextInt()
        label.text = String(describing: choice)
    }
    
    // MARK: Touch functions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.first != nil else { return }
        
        throwDice6()
    }
}

