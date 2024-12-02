/**
 
 # Explore SKView properties
 
 Achraf Kassioui
 Created: 19 April 2024
 Updated: 19 April 2024
 
 */

import SwiftUI
import SpriteKit

struct ViewPropertiesView: View {
    var myScene = ViewPropertiesScene()
    
    var body: some View {
        SpriteView(
            scene: myScene,
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
            debugOptions: [.showsFPS, .showsDrawCount, .showsNodeCount, .showsPhysics]
        )
        //.ignoresSafeArea()
    }
}

#Preview {
    ViewPropertiesView()
}

class ViewPropertiesScene: SKScene {
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        backgroundColor = SKColor(white: 1, alpha: 1)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.speed = 1
        let physicsBoundaries = CGRect(
            x: -view.frame.width / 2,
            y: -view.frame.height / 2,
            width: view.frame.width,
            height: view.frame.height
        )
        physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBoundaries)
        
        let viewFrame = SKShapeNode(rectOf: CGSize(width: view.frame.width, height: view.frame.height))
        viewFrame.lineWidth = 3
        viewFrame.strokeColor = SKColor(white: 0, alpha: 0.9)
        addChild(viewFrame)
        
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.zPosition = 999
        camera = inertialCamera
        addChild(inertialCamera)
        inertialCamera.setScale(1)
        
        let backgroundTexture = generateGridTexture(cellSize: 60, rows: 30, cols: 30, linesColor: SKColor(white: 0, alpha: 0.3))
        let background = SKSpriteNode(texture: backgroundTexture)
        addChild(background)
        
        let sprite = SKSpriteNode(imageNamed: "block_circle")
        sprite.colorBlendFactor = 1
        sprite.color = .systemRed
        sprite.size = CGSize(width: 60, height: 60)
        
        cloneNode(
            rows: 6,
            columns: 3,
            distance: 120,
            offset: CGPoint(x: -30, y: -30),
            nodeToDuplicate: sprite,
            parent: self
        )
    }
    
    func cloneNode(rows: Int, columns: Int, distance: CGFloat, offset: CGPoint, nodeToDuplicate: SKNode, parent: SKScene) {
        /// calculate the starting position for the grid with offset
        let startX = offset.x - CGFloat(columns - 1) * distance / 2
        let startY = offset.y + CGFloat(rows - 1) * distance / 2
        
        /// iterate through each row and column to create and position the nodes
        for row in 0..<rows {
            for col in 0..<columns {
                /// duplicate the provided node
                let newNode = nodeToDuplicate.copy() as! SKNode
                
                /// calculate the position for the current node with offset
                let posX = startX + CGFloat(col) * distance
                let posY = startY - CGFloat(row) * distance
                
                /// set the position of the new node and add it to the scene
                newNode.position = CGPoint(x: posX, y: posY)
                parent.addChild(newNode)
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.update()
        }
    }
}
