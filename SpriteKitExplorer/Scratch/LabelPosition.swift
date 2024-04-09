/**
 
 # A scratch file for
 
 This moron who doesn't deserve help
 https://stackoverflow.com/questions/78248438/label-not-showing-on-tutorial-skscene
 
 Achraf Kassioui
 Created: 1 April 2024
 Updated: 1 April 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - Live preview

struct LabelPositionView: View {
    var myScene = Start()
    
    var body: some View {
        SpriteView(
            scene: myScene,
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
            debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS]
        )
        //.ignoresSafeArea()
        .background(.gray)
        .statusBar(hidden: true)
    }
}

#Preview {
    LabelPositionView()
}

class Start: SKScene {
    
    private var label : SKLabelNode?
    private var PlayButton : SKSpriteNode?
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        
        // Create a label node
        let labelNode = SKLabelNode(text: "Block Maze")
        
        // Set position of the label just below the top with a fixed margin
        let topMargin: CGFloat = 100 // Adjust this value for the desired margin
        labelNode.position = CGPoint(x: self.size.width / 2, y: self.size.height - topMargin)
        
        // Add the label node to the scene
        self.addChild(labelNode)
        
        // Print the position of the label
        print("Label position: \(labelNode.position)")
        
        // Create a play button box
        let buttonSize = CGSize(width: 150, height: 60)
        let playButtonBox = SKShapeNode(rectOf: buttonSize, cornerRadius: 10)
        playButtonBox.fillColor = SKColor.clear
        playButtonBox.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        
        // Create a label node for the play button text
        let playLabel = SKLabelNode(text: "Play")
        playLabel.fontColor = .white
        playLabel.fontSize = 24
        playLabel.position = CGPoint(x: 0, y: -10) // Adjust this value to position the text inside the box
        
        playButtonBox.name = "playButton" // Set the name property
        
        // Add the label node as a child of the button box
        playButtonBox.addChild(playLabel)
        
        // Add the play button box to the scene
        self.addChild(playButtonBox)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            // Check if the touch is on the play button
            if let node = self.atPoint(location) as? SKShapeNode, node.name == "playButton" {
                // Perform the action when the play button is tapped
                print("Play button tapped!")
                
                // Add your code here to perform the desired action
                
                //Go to Tutorial
                // Create and present the scene
                // Create and present the scene
                if let tutorialScene = SKScene(fileNamed: "Tutorial") {
                    tutorialScene.scaleMode = .fill
                    
                    // Present the TutorialScene
                    self.view?.presentScene(tutorialScene)
                    
                }
            }
        }
    }
}
