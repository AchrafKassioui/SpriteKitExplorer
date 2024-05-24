/**
 
 # Action Playground
 
 A playground file to experiment with SKAction in SpriteKit.
 
 Achraf Kassioui
 Created: 22 April 2024
 Updated: 22 April 2024
 
 */

import SwiftUI
import SpriteKit
import CoreImage.CIFilterBuiltins

// MARK: - Live preview

struct ActionsPlaygroundView: View {
    @State private var sceneId = UUID()
    
    var body: some View {
        SpriteView(
            scene: ActionsPlaygroundScene(),
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
            debugOptions: [.showsFPS, .showsDrawCount, .showsNodeCount]
        )
        /// force recreation using the unique ID
        .id(sceneId)
        .onAppear {
            /// generate a new ID on each appearance
            sceneId = UUID()
        }
        //.ignoresSafeArea()
    }
}

#Preview {
    ActionsPlaygroundView()
}

// MARK: - SpriteKit

class ActionsPlaygroundScene: SKScene {
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        backgroundColor = SKColor(white: 1, alpha: 1)
        
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.zPosition = 999
        camera = inertialCamera
        addChild(inertialCamera)
        
        let backgroundTexture = generateGridTexture(cellSize: 60, rows: 30, cols: 30, linesColor: SKColor(white: 0, alpha: 0.3))
        let background = SKSpriteNode(texture: backgroundTexture)
        background.zPosition = -1
        addChild(background)
        
        squareMotion()
    }
    
    // MARK: - Actions
    
    func squareMotion() {
        let spriteSize = CGSize(width: 60, height: 60)
        let sprite = SKSpriteNode(color: .systemRed, size: spriteSize)
        addChild(sprite)
        
        let right = SKAction.moveBy(x: 200, y: 0, duration: 1)
        right.timingMode = .easeInEaseOut
        let left = SKAction.moveBy(x: -200, y: 0, duration: 1)
        left.timingMode = .easeInEaseOut
        let down = SKAction.moveBy(x: 0, y: -200, duration: 1)
        down.timingMode = .easeInEaseOut
        let up = SKAction.moveBy(x: 0, y: 200, duration: 1)
        up.timingMode = .easeInEaseOut
        
        let sequence = SKAction.sequence([right,down,left,up])
        let moveSequence = SKAction.repeatForever(sequence)
        sprite.run(moveSequence)
    }
    
    // MARK: - Update loop
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.updateInertia()
        }
    }
}
