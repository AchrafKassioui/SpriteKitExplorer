//
//  Text.swift
//  SpriteKitExplorer
//
//  Created by Achraf Kassioui on 28/1/2024.
//

/**
 
 # Text
 
 A basic setup for throwing object with inertia.
 Drag and throw the ball to try. The inertia after release uses physics.
 Uses SpriteKit touch event handling abd the update loop. Does not use UIKit gesture recognizer
 
 Drawbacks:
 - Uses a hardcoded framerate value to calculate the time the object took to travel a distance.
 - Assumes the object has a physicsBody, and overwrites its velocity.
 
 Created: 26 January 2024
 
 */

import UIKit
import SwiftUI
import SpriteKit
import Observation

// MARK: - SwiftUI

struct SpriteKitText: View {
    @State var myScene = TextScene()
    
    var body: some View {
        ZStack {
            ZStack {
                SpriteView(
                    scene: myScene,
                    preferredFramesPerSecond: 120,
                    options: [.ignoresSiblingOrder],
                    debugOptions: [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount, .showsPhysics]
                )
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - SpriteKit

@Observable class TextScene: SKScene {
    
    var anObject: SKShapeNode!
    
    // MARK: Scene
    
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .lightGray
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        addCenteredMultilineText()
    }
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
    }
    
    // MARK: Objects
    
    func addCenteredMultilineText() {
        let text = "The quick brown fox jumps over the lazy dog"
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineHeightMultiple = 1.3
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Menlo Bold", size: 24)!,
            .foregroundColor: UIColor(white: 1, alpha: 1),
            .paragraphStyle: paragraphStyle,
            .kern: 1.0,
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)

        let label = SKLabelNode()
        label.numberOfLines = 0
        label.verticalAlignmentMode = .center
        label.preferredMaxLayoutWidth = 360
        label.attributedText = attributedText
        addChild(label)
    }
}

//#Preview {
//    SpriteKitText()
//}
