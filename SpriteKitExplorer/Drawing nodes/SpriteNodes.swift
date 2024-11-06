/**
 
 # Experimenting with SKSpriteNode
 
 Created: 9 March 2024
 Updated: 17 March 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct SpriteNodesPreview: View {
    var myScene = SpriteNodesScene()
    
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
    SpriteNodesPreview()
}

// MARK: - Scene setup

class SpriteNodesScene: SKScene {
    
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
    }
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        scene?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        physicsWorld.speed = 1
        physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        let cameraNode = InertialCamera(scene: self)
        addChild(cameraNode)
        camera = cameraNode
        
        /// comment/uncomment to execute various examples
        //drawSprites()
        drawSpriteWithShadow()
    }
    
    // MARK: - Shadow sprite
    
    func drawSpriteWithShadow() {
        let background = SKSpriteNode(imageNamed: "abstract-dunes-1024")
        background.setScale(2.4)
        background.texture?.filteringMode = .nearest
        background.zPosition = -1
        //addChild(background)
        
        let shadowTexture = generateShadowTexture(
            width: 60,
            height: 180,
            cornerRadius: 12,
            shadowOffset: CGSize( width: 0, height: 4),
            shadowBlurRadius: 20,
            shadowColor: SKColor(white: 0, alpha: 0.6)
        )
        
        let shadowSprite = SKSpriteNode(texture: shadowTexture)
        shadowSprite.position.y = -5
        shadowSprite.zPosition = 10
        shadowSprite.blendMode = .multiplyAlpha
        addChild(shadowSprite)
    }
    
    // MARK: - drawing sprites
    
    func drawSprites() {
        /// apply a Core Image filter to the texture
        /// pass one of the premade filters below to the SKTexture function
        let farfalleTexture = SKTexture(imageNamed: "concave_shape_1").applying(MyFilters.dither(intensity: 1))
        let farfalleSprite = SKSpriteNode(texture: farfalleTexture)
        farfalleSprite.physicsBody = SKPhysicsBody(texture: farfalleTexture, size: farfalleTexture.size())
        farfalleSprite.position = CGPoint(x: 0, y: 300)
        addChild(farfalleSprite)
        
        /// a sprite made from a texture with some thin parts
        /// used to test if physics body will conform to the most thinner parts of the texture
        let chainTexture = SKTexture(imageNamed: "chain_sprite")
        let chainSprite = SKSpriteNode(texture: chainTexture)
        chainSprite.physicsBody = SKPhysicsBody(texture: chainTexture, size: chainTexture.size())
        chainSprite.position = CGPoint(x: 0, y: 150)
        addChild(chainSprite)
        
        /// a very concave texture to stress test physics body generation
        let concaveTexture = SKTexture(imageNamed: "edge_shape_2")
        let concaveSprite = SKSpriteNode(texture: concaveTexture, size: concaveTexture.size())
        concaveSprite.color = SKColor.white.withAlphaComponent(1)
        concaveSprite.colorBlendFactor = 1
        concaveSprite.physicsBody = SKPhysicsBody(texture: concaveTexture, size: concaveTexture.size())
        concaveSprite.physicsBody?.density = 100
        addChild((concaveSprite))
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



