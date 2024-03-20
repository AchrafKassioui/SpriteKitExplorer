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
        let camera = SKCameraNode()
        let viewSize = view?.bounds.size
        camera.xScale = (viewSize!.width / size.width)
        camera.yScale = (viewSize!.height / size.height)
        addChild(camera)
        scene?.camera = camera
        camera.setScale(1)
    }
    
    func setupLabel() {
        label.text = ""
        label.fontName = "Menlo-Bold"
        label.fontSize = 32
        label.zPosition = 1
        addChild(label)
    }
    
    // MARK: GameplayKit functions
    
    func customDice(min: Int, max: Int) {
        let customDice = GKRandomDistribution(lowestValue: min, highestValue: max)
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
        
        customDice(min: 1, max: 256)
    }
}

