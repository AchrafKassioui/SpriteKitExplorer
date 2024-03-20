//
//  Keyframes.swift
//  SpriteKitExplorer
//
//  Created by Achraf Kassioui on 16/3/2024.
//

/**
 
 # Keyframes
 
 Trigger animations at specific time stamps
 
 Created: 16 March 2024
 
 */

import SwiftUI
import SpriteKit

struct KeyframesView: View {
    var myScene = KeyframesScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    KeyframesView()
}

class KeyframesScene: SKScene {
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .darkGray
    }
}
