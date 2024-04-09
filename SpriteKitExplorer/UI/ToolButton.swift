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

// MARK: The subclass

class ButtonWithIconAndLabel: SKShapeNode {
    
    init(name: String, size: CGSize, icon: String, parent: SKNode, label: String? = nil) {
        super.init()
        
        let origin = CGPoint(x: -size.width / 2, y: -size.height / 2)
        let rect = CGRect(origin: origin, size: size)
        let cornerRadius: CGFloat = 7.0
        self.path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        self.name = name
        self.lineWidth = 1
        self.strokeColor = .black.withAlphaComponent(0.6)
        self.fillColor = SKColor.white.withAlphaComponent(0.6)
        
        // Add the icon as a child
        let iconNode = SKSpriteNode(imageNamed: icon)
        iconNode.zPosition = self.zPosition + 1
        self.addChild(iconNode)
        
        // If a label is provided, add it below the icon
        if let labelText = label {
            let labelNode = SKLabelNode(text: labelText)
            labelNode.fontName = "SFMono-Regular"
            labelNode.fontSize = 50
            labelNode.setScale(0.2)
            labelNode.fontColor = UIColor.black.withAlphaComponent(0.6)
            
            // Adjust the label's position based on the icon's size
            labelNode.position = CGPoint(x: 0, y: -(size.height / 2) + 10)
            labelNode.zPosition = self.zPosition + 2
            iconNode.position.y = 8
            
            self.addChild(labelNode)
        }
        
        parent.addChild(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


