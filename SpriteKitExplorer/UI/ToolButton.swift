/**
 
 # A subclass for the tools buttons
 
 Created: 6 March 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI for previewing the sublcass

struct ToolButtonPreview: View {
    var body: some View {
        SpriteView(
            scene: ToolButtonExampleScene(),
            preferredFramesPerSecond: 120,
            options: [.ignoresSiblingOrder],
            debugOptions: [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount]
        )
        .ignoresSafeArea()
        .background(.black)
    }
}

#Preview {
    ToolButtonPreview()
}

// MARK: - SpriteKit

class ToolButtonExampleScene: SKScene {
    
    // MARK: Scene setup
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
    }
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        scene?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        createObjects()
    }
    
    func createObjects() {
        let button = ButtonWithIconAndLabel(
            name: "button",
            size: CGSize(width: 60, height: 60),
            icon: "material_tool",
            label: "Color"
        )
        addChild(button)
    }
}


