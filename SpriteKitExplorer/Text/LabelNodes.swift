/**
 
 # Experimenting with SKLabelNode
 
 Created: 13 March 2024
 Updated: 14 October 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI
struct LabelNodesView: View {
    var myScene = LabelNodesScene()
    @State private var selectedText = 2
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene
            )
            .edgesIgnoringSafeArea(.all)
            .onAppear() {
                myScene.highlightedText()
            }
            VStack {
                Spacer()
                Picker("Select Text", selection: $selectedText) {
                    Text("Multlines").tag(1)
                    Text("Highlighted").tag(2)
                    Text("Long").tag(3)
                    Text("Text FX").tag(4)
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: selectedText) {
                    if selectedText == 1 {
                        myScene.createMultipleLines()
                    } else if selectedText == 2 {
                        myScene.highlightedText()
                    } else if selectedText == 3 {
                        myScene.longParagraph()
                    } else if selectedText == 4 {
                        myScene.textFX()
                    }
                }
            }
        }
    }
}

#Preview {
    LabelNodesView()
}

// MARK: SpriteKit
class LabelNodesScene: SKScene {
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(hex: "#dddddd") ?? .white
        
        let myCamera = InertialCamera(scene: self)
        camera = myCamera
        addChild(myCamera)
    }
    
    func clearAllText(nodeName: String) {
        self.enumerateChildNodes(withName: "//\(nodeName)") { node, _ in
            node.removeFromParent()
        }
    }
    
    // MARK: Label
    
    func createMultipleLines() {
        clearAllText(nodeName: "text")
        
        /**
         
         SpriteKit renders label nodes as raster objects. Therefore if the camera is zoomed in, label will appear aliased.
         A hack around it is to increase the font size of the label, then scale down the node.
         This scale factor workaround bakes in more details in the label, allowing the camera to zoom without aliasing.
         
         */
        let scaleFactor: CGFloat = 4
        
        let myLabel = SKLabelNode(text: "This text uses SpriteKit built-in properties to draw text on multiple lines.")
        myLabel.name = "text"
        myLabel.preferredMaxLayoutWidth = 360 * scaleFactor
        myLabel.numberOfLines = 0
        myLabel.lineBreakMode = .byTruncatingTail
        myLabel.fontName = "CormorantGaramond-Regular"
        myLabel.fontSize = 32 * scaleFactor
        myLabel.fontColor = .black
        myLabel.horizontalAlignmentMode = .center
        myLabel.verticalAlignmentMode = .center
        myLabel.setScale(1 / scaleFactor)
        addChild(myLabel)
    }
    
    // MARK: Attributed String
    /**
     
     Below are text effects made using `NSAttributedString`.
     SKLabelNode's `attributedText` property is a bridge with NSAttributedString.
     Many text properties and settings can be borrowed from NSAttributedString and applied that way inside SpriteKit.
     
     */
    func highlightedText() {
        clearAllText(nodeName: "text")
        
        let text = "This string of text uses attributed strings to change its font, add paragraph indentation, background color, and text shadow."
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .natural
        paragraphStyle.lineHeightMultiple = 1
        paragraphStyle.firstLineHeadIndent = 32
        
        let shadow = NSShadow()
        shadow.shadowOffset = CGSize(width: 0, height: 10)
        shadow.shadowColor = SKColor.black.withAlphaComponent(0.4)
        shadow.shadowBlurRadius = 10
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "CormorantGaramond-Regular", size: 32)!,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: SKColor(white: 0, alpha: 0.8),
            .backgroundColor: SKColor.yellow,
            .kern: 1.0,
            .shadow: shadow
        ]
        
        let label = SKLabelNode()
        label.name = "text"
        label.attributedText = NSAttributedString(string: text, attributes: attributes)
        label.numberOfLines = 0
        label.verticalAlignmentMode = .center
        label.preferredMaxLayoutWidth = 360
        addChild(label)
    }
    
    func longParagraph() {
        clearAllText(nodeName: "text")
        
        let text = """
There are 2 aspects that these experiments make me think about.

1. Mathematics. While observing the spatial behavior of elements on a grid, I can see what keeps a mathematician awake: there is a mechanical necessity in the relations between the elements that begs to be resolved. We can feel that the behavior is not random, and that there must be a logical point of view from which the phenomenological results can be derived (phenomenologically means “how things appear”).

2. Thinking tools. Up until this point, I still don’t know which mathematical framework generalizes and captures the behavior I saw in the simulations. I wrote an algorithm and I ran a computer program with various parameters, which was fun, tedious (any programming is), and thought-provoking. But I still lack a deeper understanding of what is happening. This argument is developed by Evan Miller in a piece called Don’t Kill Math, in which he criticizes an article written by Bret Victor called Kill Math.
"""
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineHeightMultiple = 1.2
        paragraphStyle.firstLineHeadIndent = 20
        
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular),
            .foregroundColor: SKColor(white: 0, alpha: 1),
            //.kern: 1.0,
            .ligature: 2
        ]
        
        let label = SKLabelNode()
        label.name = "text"
        label.attributedText = NSAttributedString(string: text, attributes: attributes)
        label.numberOfLines = 0
        label.verticalAlignmentMode = .center
        label.preferredMaxLayoutWidth = size.width - 80
        addChild(label)
    }
    
    func textFX() {
        guard let view = view else { return }
        
        clearAllText(nodeName: "text")
        
        let text = "BAM!"
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineHeightMultiple = 1
        
        let shadow = NSShadow()
        shadow.shadowOffset = CGSize(width: 0, height: 10)
        shadow.shadowColor = SKColor.black.withAlphaComponent(0.3)
        shadow.shadowBlurRadius = 20
        
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont(name: "ChalkboardSE-Bold", size: 100)!,
            .foregroundColor: #colorLiteral(red: 1, green: 0.9507730603, blue: 0, alpha: 1),
            .strokeColor: #colorLiteral(red: 1, green: 0, blue: 0.3822745085, alpha: 1),
            .strokeWidth: -5,
            .shadow: shadow,
        ]
        
        let label = SKLabelNode()
        label.attributedText = NSAttributedString(string: text, attributes: attributes)
        label.numberOfLines = 0
        label.verticalAlignmentMode = .center
        
        let textTexture = view.texture(from: label)
        let textSprite = SKSpriteNode(texture: textTexture)
        textSprite.name = "text"
        textSprite.texture?.filteringMode = .nearest
        addChild(textSprite)
    }
    
    // MARK: Update loop
    
    override func update(_ currentTime: TimeInterval) {
        if let myCamera = camera as? InertialCamera {
            myCamera.update()
        }
    }
    
    // MARK: Touch events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.stopInertia()
        }
    }
}
