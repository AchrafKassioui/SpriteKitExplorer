/**
 
 # Core Graphics and SpriteKit
 
 A SwiftUI and SpriteKit demo scene for Core Graphics Generators
 
 Created: 18 March 2024
 Updated: 19 April 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct CGDemoView: View {
    var myScene = CGDemoScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                preferredFramesPerSecond: 120,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount]
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    CGDemoView()
}

// MARK: - SpriteKit

class CGDemoScene: SKScene {
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        backgroundColor = .lightGray
        scene?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        physicsWorld.speed = 1
        physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        let inertialCamera = InertialCamera(scene: self)
        camera = inertialCamera
        addChild(inertialCamera)
        
        /// comment/uncomment to execute various examples
        //drawSpriteWithShadow()
        //drawCheckerboard()
        drawGrid()
    }
    
    // MARK: Generated nodes
    
    func drawCheckerboard() {
        let checkerboardTexture = generateCheckerboardTexture(cellSize: 60, rows: 5, cols: 5)
        let checkerboard = SKSpriteNode(texture: checkerboardTexture)
        addChild(checkerboard)
    }
    
    func drawGrid() {
        let gridTexture = generateGridTexture(cellSize: 60, rows: 20, cols: 20, linesColor: SKColor(white: 1, alpha: 1))
        let gridbackground = SKSpriteNode(texture: gridTexture)
        addChild(gridbackground)
    }
    
    func drawSpriteWithShadow() {
        let shadowTexture = generateShadowTexture(
            width: 60,
            height: 180,
            cornerRadius: 12,
            shadowOffset: CGSize(width: 0, height: 20),
            shadowBlurRadius: 20,
            shadowColor: SKColor(white: 0, alpha: 0.6)
        )
        
        let shadowSprite = SKSpriteNode(texture: shadowTexture)
        shadowSprite.blendMode = .multiplyAlpha
        addChild(shadowSprite)
        
        /// visualize the frame of the sprite
        let boundingBox = SKShapeNode(rect: shadowSprite.calculateAccumulatedFrame())
        shadowSprite.addChild(boundingBox)
    }
    
    // MARK: Update loop
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.updateInertia()
        }
    }
    
    // MARK: Touch events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.stopInertia()
        }
    }
    
}

/// A SKSpriteNode subclass that creates a sprite from texture
/// and add some functions
/// credit: https://stackoverflow.com/a/33471755/420176
/// edited with newer Core Graphics APIs
class CellSprite: SKSpriteNode {
    var rows: Int
    var cols: Int
    var cellSize: CGFloat
    
    init(cellSize: CGFloat, rows: Int, cols: Int) {
        let texture = generateCheckerboardTexture(cellSize: cellSize, rows: rows, cols:cols)
        self.cellSize = cellSize
        self.rows = rows
        self.cols = cols
        super.init(texture: texture, color: SKColor.clear, size: texture.size())
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// get the coordinates of a specific cell in the grid
    func getCellPosition(row: Int, col: Int) -> CGPoint {
        let offset = cellSize / 2.0 + 0.5
        let x = CGFloat(col) * cellSize - (cellSize * CGFloat(cols)) / 2.0 + offset
        let y = CGFloat(rows - row - 1) * cellSize - (cellSize * CGFloat(rows)) / 2.0 + offset
        return CGPoint(x: x, y: y)
    }
    
    /// determine which cell was touched
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let position = touch.location(in:self)
            let node = atPoint(position)
            if node != self {
                let action = SKAction.rotate(byAngle: .pi * 2, duration: 1)
                node.run(action)
            }
            else {
                let x = size.width / 2 + position.x
                let y = size.height / 2 - position.y
                let row = Int(floor(x / cellSize))
                let col = Int(floor(y / cellSize))
                print("Cell position: \(row) \(col)")
            }
        }
    }
}



