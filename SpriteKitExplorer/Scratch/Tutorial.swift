//
//  Tutorial.swift
//  SpriteKitExplorer
//
//  Created by Achraf Kassioui on 1/4/2024.
//

import SpriteKit
import GameplayKit

class Tutorial: SKScene {
    
    override func didMove(to view: SKView) {
        print("Tutorial scene did move to view.") // Confirm that the scene's didMove(to:) method is called
        
        
        // Create a label node
        let labelNode = SKLabelNode(text: "Block Maze")
        labelNode.fontColor = SKColor.black // Set label text color
        labelNode.fontSize = 24 // Set label font size
        
        // Set position of the label just below the top with a fixed margin
        let topMargin: CGFloat = 100 // Adjust this value for the desired margin
        labelNode.position = CGPoint(x: self.size.width / 2, y: self.size.height - topMargin)
        
        labelNode.position = CGPoint(x: 0, y: (self.size.height / 2) - topMargin)
        
        // Add the label node to the scene
        self.addChild(labelNode)
        
        // Print the position of the label
        print("Label position: \(labelNode.position)")
    }
    
}
