/**
 
 # Core Graphics and SpriteKit
 
 A SwiftUI and SpriteKit demo scene for Core Graphics Generators.
 
 Created: 18 March 2024
 Updated: 21 October 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct CGDemoView: View {
    var myScene = CGDemoScene()
    @State private var selectedFunction: Int = 0
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                preferredFramesPerSecond: 120,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount]
            )
            .ignoresSafeArea()
            VStack {
                Spacer()
                Picker("Select a Core Graphics function", selection: $selectedFunction) {
                    Text("Grid").tag(0)
                    Text("Checkerboard").tag(1)
                    Text("Drop Shadow").tag(2)
                    Text("Stripes").tag(3)
                    Text("Dot Pattern").tag(4)
                }
                .pickerStyle(.inline)
                .onChange(of: selectedFunction) {
                    if selectedFunction == 0 {
                        myScene.drawGrid()
                    } else if selectedFunction == 1 {
                        myScene.drawCheckerboard()
                    } else if selectedFunction == 2 {
                        myScene.drawSpriteWithShadow()
                    } else if selectedFunction == 3 {
                        myScene.drawStripes()
                    } else if selectedFunction == 4 {
                        myScene.drawDotPattern()
                    }
                }
                
            }
        }
    }
}

#Preview {
    CGDemoView()
}

// MARK: - SpriteKit

class CGDemoScene: SKScene {
    
    var objectLayer = SKNode()
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        backgroundColor = .gray
        
        let inertialCamera = InertialCamera(scene: self)
        camera = inertialCamera
        addChild(inertialCamera)
        
        addChild(objectLayer)
        
        drawDotPattern()
    }
    
    func clearCanvas() {
        objectLayer.removeAllChildren()
    }
    
    // MARK: Drawing Functions
    
    func drawStripes() {
        clearCanvas()
        
        let texture = generateStripedTexture(
            size: CGSize(width: 300, height: 300),
            colorA: .black,
            colorB: .lightGray,
            stripeHeight: 6
        )
        let sprite = SKSpriteNode(texture: texture)
        objectLayer.addChild(sprite)
    }
    
    func drawDotPattern () {
        clearCanvas()
        
        let texture = generateDotPatternTexture(
            size: CGSize(width: 400, height: 800),
            color: .black,
            pattern: .staggered,
            dotSize: 3,
            spacing: 10,
            cornerRadius: 0,
            rotation: 0
        )
        let sprite = SKSpriteNode(texture: texture)
        objectLayer.addChild(sprite)
    }
    
    func drawCheckerboard() {
        clearCanvas()
        let checkerboardTexture = generateCheckerboardTexture(cellSize: 60, rows: 5, cols: 5)
        let checkerboard = SKSpriteNode(texture: checkerboardTexture)
        objectLayer.addChild(checkerboard)
    }
    
    func drawGrid() {
        clearCanvas()
        let gridTexture = generateGridTexture(cellSize: 60, rows: 20, cols: 20, linesColor: SKColor(white: 1, alpha: 1))
        let gridbackground = SKSpriteNode(texture: gridTexture)
        objectLayer.addChild(gridbackground)
    }
    
    func drawSpriteWithShadow() {
        clearCanvas()
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
        objectLayer.addChild(shadowSprite)
        
        /// visualize the frame of the sprite
        //let boundingBox = SKShapeNode(rect: shadowSprite.calculateAccumulatedFrame())
        //shadowSprite.addChild(boundingBox)
    }
    
    // MARK: Update loop
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.update()
        }
    }
    
    // MARK: Touch events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.stopInertia()
        }
    }
    
}



