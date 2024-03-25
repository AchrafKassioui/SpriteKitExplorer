/**
 
 # Core Graphics and SpriteKit
 
 Created: 18 March 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct CoreGraphicsView: View {
    var myScene = CoreGraphicsScene()
    
    var body: some View {
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

#Preview {
    CoreGraphicsView()
}

// MARK: - SpriteKit

class CoreGraphicsScene: SKScene {
    
    // MARK: Scene setup
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .darkGray
    }
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        scene?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        physicsWorld.speed = 1
        physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        setupCamera()
        
        /// comment/uncomment to execute various examples
        //drawSpriteWithShadow()
        drawCellsWithPositionDetection()
        //drawCheckerboard()
        //drawGrid()
    }
    
    func setupCamera() {
        let camera = SKCameraNode()
        let viewSize = view?.bounds.size
        camera.xScale = (viewSize!.width / size.width)
        camera.yScale = (viewSize!.height / size.height)
        addChild(camera)
        scene?.camera = camera
        camera.setScale(1)
    }
    
    // MARK: Generated nodes
    
    func drawSpriteWithShadow() {
        let background = SKSpriteNode(imageNamed: "abstract-dunes-1024")
        background.setScale(2.4)
        background.texture?.filteringMode = .nearest
        background.zPosition = -1
        addChild(background)
        
        let shadowTexture = createShadowTexture(
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
    
    func drawCheckerboard() {
        if let checkerboardTexture = generateCheckerboardTexture(cellSize: 60, rows: 5, cols: 5) {
            let checkerboard = SKSpriteNode(texture: checkerboardTexture)
            addChild(checkerboard)
        }
    }
    
    func drawGrid() {
        if let gridTexture = generateGridTexture(cellSize: 60, rows: 20, cols: 20) {
            let gridbackground = SKSpriteNode(texture: gridTexture)
            addChild(gridbackground)
        }
    }
    
    func drawCellsWithPositionDetection() {
        let sprite = SKSpriteNode(color: SKColor.red, size: CGSize(width: 50, height: 50))
        sprite.name = "sprite"
        addChild(sprite)
        
        if let checkerboard = cellSprite(cellSize: 60, rows: 5, cols: 5) {
            checkerboard.name = "checkerboard"
            addChild(checkerboard)
            checkerboard.zPosition = -1
            sprite.position = checkerboard.getCellPosition(row: 2, col: 2)
            sprite.position.y -= 1
        }
    }
    
}

// MARK: - Core graphics

/// create shadow texture
func createShadowTexture(width: CGFloat, height: CGFloat, cornerRadius: CGFloat, shadowOffset: CGSize, shadowBlurRadius: CGFloat, shadowColor: SKColor) -> SKTexture {
    // Calculate the size of the texture to accommodate the shadow
    let textureSize = CGSize(width: width + shadowBlurRadius * 2 + abs(shadowOffset.width), height: height + shadowBlurRadius * 2 + abs(shadowOffset.height))
    
    // Create a renderer with the calculated size
    let renderer = UIGraphicsImageRenderer(size: textureSize)
    
    let image = renderer.image { ctx in
        let context = ctx.cgContext
        
        // Move the origin of the rectangle to accommodate the shadow
        let rectOrigin = CGPoint(x: (textureSize.width - width) / 2 + shadowOffset.width, y: (textureSize.height - height) / 2 - shadowOffset.height)
        let rect = CGRect(origin: rectOrigin, size: CGSize(width: width, height: height))
        
        // Set shadow properties
        context.setShadow(offset: shadowOffset, blur: shadowBlurRadius, color: shadowColor.cgColor)
        
        // Set fill color to clear to make the inside of the rectangle transparent
        //context.setFillColor(SKColor.red.cgColor)
        context.setFillColor(SKColor(white: 1, alpha: 1).cgColor)
        
        // Draw the rounded rectangle with the shadow
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath
        context.addPath(path)
        context.fillPath()
    }
    
    // Convert the image to an SKTexture
    return SKTexture(image: image)
}

/// checkerboard generator with Core Graphics
func generateCheckerboardTexture(cellSize: CGFloat, rows: Int, cols: Int) -> SKTexture? {
    let size = CGSize(width: CGFloat(cols) * cellSize, height: CGFloat(rows) * cellSize)
    
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { ctx in
        let context = ctx.cgContext
        
        /// Draw checkerboard cells
        for row in 0..<rows {
            for col in 0..<cols {
                /// Determine cell color: black for even sum of indexes, white for odd
                let isBlackCell = ((row + col) % 2 == 0)
                context.setFillColor(isBlackCell ? SKColor(white: 0, alpha: 1).cgColor : SKColor(white: 1, alpha: 1).cgColor)
                
                /// Calculate cell frame
                let cellFrame = CGRect(x: CGFloat(col) * cellSize, y: CGFloat(row) * cellSize, width: cellSize, height: cellSize)
                
                /// Fill cell
                context.fill(cellFrame)
            }
        }
    }
    
    return SKTexture(image: image)
}

/// grid generator with Core Graphics
func generateGridTexture(cellSize: CGFloat, rows: Int, cols: Int) -> SKTexture? {
    /// Add 1 to the height and width to ensure the borders are within the sprite
    let size = CGSize(width: CGFloat(cols) * cellSize + 1, height: CGFloat(rows) * cellSize + 1)
    
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { ctx in
        //let context = ctx.cgContext
        
        /// set shadow
        //let shadowColor = SKColor(white: 0, alpha: 0.6).cgColor
        //context.setShadow(offset: CGSize(width: 0, height: 2), blur: 1, color: shadowColor)
        
        /// fill the background
        //context.setFillColor(SKColor(white: 1, alpha: 0.2).cgColor)
        //context.fill(CGRect(origin: .zero, size: size))
        
        let bezierPath = UIBezierPath()
        let offset: CGFloat = 0.5
        /// vertical lines
        for i in 0...cols {
            let x = CGFloat(i) * cellSize + offset
            bezierPath.move(to: CGPoint(x: x, y: 0))
            bezierPath.addLine(to: CGPoint(x: x, y: size.height))
        }
        /// horizontal lines
        for i in 0...rows {
            let y = CGFloat(i) * cellSize + offset
            bezierPath.move(to: CGPoint(x: 0, y: y))
            bezierPath.addLine(to: CGPoint(x: size.width, y: y))
        }
        
        /// stroke style
        SKColor(white: 1, alpha: 1).setStroke()
        bezierPath.lineWidth = 1
        
        /// draw
        bezierPath.stroke()
    }
    
    return SKTexture(image: image)
}

/// A SKSpriteNode subclass that creates a sprite from texture
/// and add some functions
/// credit: https://stackoverflow.com/a/33471755/420176
/// edited with newer Core Graphics APIs
class cellSprite: SKSpriteNode {
    var rows: Int!
    var cols: Int!
    var cellSize: CGFloat!
    
    convenience init?(cellSize: CGFloat, rows: Int, cols: Int) {
        guard let texture = generateCheckerboardTexture(cellSize: cellSize, rows: rows, cols:cols) else {
            return nil
        }
        self.init(texture: texture, color: SKColor.clear, size: texture.size())
        self.cellSize = cellSize
        self.rows = rows
        self.cols = cols
        self.isUserInteractionEnabled = true
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
                //let action = SKAction.rotate(by: .pi * 2, duration: 1)
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



