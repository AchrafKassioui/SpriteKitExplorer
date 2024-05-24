/**
 
 # A subclass for the tools buttons
 
 Created: 6 March 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI for previewing the sublcass

struct ToolButtonPreview: View {
    var myScene = ToolButtonExampleScene()
    @State private var debugOptions: SpriteView.DebugOptions = [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount]
    
    var body: some View {
        VStack {
            ZStack {
                SpriteView(
                    scene: myScene,
                    preferredFramesPerSecond: 120,
                    options: [.ignoresSiblingOrder],
                    debugOptions: debugOptions
                )
                .ignoresSafeArea()
                
                HStack {
                    Spacer()
                    VStack {
                        Button("Debug") {
                            
                        }
                        .padding()
                        Spacer()
                    }
                }
            }
            HStack {
                Spacer()
            }
        }
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
        createObjects(in: view)
    }
    
    func createObjects(in view: SKView) {
        guard let scene = scene else { return }
        let _ = ButtonWithIconAndLabel(
            name: "button",
            size: CGSize(width: 60, height: 60),
            icon: "material_tool",
            parent: scene,
            label: "Color"
        )
    }
}


