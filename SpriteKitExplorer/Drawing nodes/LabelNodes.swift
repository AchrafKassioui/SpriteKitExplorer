//
//  LabelNodes.swift
//  SpriteKitExplorer
//
//  Created by Achraf Kassioui on 13/3/2024.
//

import SwiftUI
import SpriteKit

struct LabelNodesView: View {
    var myScene = LabelNodesScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                debugOptions: [.showsFPS]
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    LabelNodesView()
}

class LabelNodesScene: SKScene {
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        createMultipleLines()
    }
    
    func createMultipleLines() {
        let myLabel = SKLabelNode(text: "The quick brown fox jumps over the lazy dog")
        myLabel.preferredMaxLayoutWidth = 300
        myLabel.numberOfLines = 0
        myLabel.lineBreakMode = .byTruncatingTail
        myLabel.fontName = "CormorantGaramond-Regular"
        myLabel.fontSize = 36
        myLabel.fontColor = .white
        myLabel.horizontalAlignmentMode = .center
        myLabel.verticalAlignmentMode = .center
        addChild(myLabel)
    }
}
