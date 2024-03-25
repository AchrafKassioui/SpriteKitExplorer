/**
 
 # Experimenting with SKLabelNode
 
 Created: 13 March 2024
 Updated: 14 March 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI
struct LabelNodesView: View {
    var myScene = LabelNodesScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene
            )
            .edgesIgnoringSafeArea(.all)
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
        
        /// comment and uncomment the following functions to see various text effects
        //createMultipleLines()
        highlightedText()
        //longParagraph()
        //strokedText()
    }
    
    func createMultipleLines() {
        let myLabel = SKLabelNode(text: "This text uses SpriteKit built-in properties to draw text on multiple lines.")
        myLabel.preferredMaxLayoutWidth = 300
        myLabel.numberOfLines = 0
        myLabel.lineBreakMode = .byTruncatingTail
        myLabel.fontName = "CormorantGaramond-Regular"
        myLabel.fontSize = 32
        myLabel.fontColor = .black
        myLabel.horizontalAlignmentMode = .center
        myLabel.verticalAlignmentMode = .center
        addChild(myLabel)
    }
    
    /// Below are text effects made using NSAttributedString
    /// SpriteKit attributedText is a bridge with NSAttributedString
    /// Many text properties and settings can be borrowed from NSAttributedString and applied to SpriteKit

    func strokedText() {
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
            .shadow: shadow
        ]
        
        let label = SKLabelNode()
        label.attributedText = NSAttributedString(string: text, attributes: attributes)
        label.numberOfLines = 0
        label.verticalAlignmentMode = .center
        addChild(label)
    }
    
    func longParagraph() {
        let text = """
There are 2 aspects that these experiments make me think about.\n 1. Mathematics. While observing the spatial behavior of elements on a grid, I can see what keeps a mathematician awake: there is a mechanical necessity in the relations between the elements that begs to be resolved. We can feel that the behavior is not random, and that there must be a logical point of view from which the phenomenological results can be derived (phenomenologically means “how things appear”).
"""
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineHeightMultiple = 1.2
        paragraphStyle.firstLineHeadIndent = 20
        
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont(name: "Chalkduster", size: 16)!,
            .foregroundColor: SKColor(white: 0, alpha: 1),
            .kern: 1.0,
            .ligature: 2
        ]
        
        let label = SKLabelNode()
        label.attributedText = NSAttributedString(string: text, attributes: attributes)
        label.numberOfLines = 0
        label.verticalAlignmentMode = .center
        label.preferredMaxLayoutWidth = size.width - 80
        addChild(label)
    }
    
    func highlightedText() {
        let text = "This string of text uses paragraph indentation, justification, background color, and text shadow."
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .natural
        paragraphStyle.lineHeightMultiple = 1.2
        paragraphStyle.firstLineHeadIndent = 20
        
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
        label.attributedText = NSAttributedString(string: text, attributes: attributes)
        label.numberOfLines = 0
        label.verticalAlignmentMode = .center
        label.preferredMaxLayoutWidth = size.width - 40
        addChild(label)
    }
}
