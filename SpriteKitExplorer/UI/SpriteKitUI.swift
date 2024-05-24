/**
 
 # UI with SpriteKit nodes
 
 Created: 4 March 2024
 
 */

import AudioToolbox
import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct SpriteKitUI: View {
    var myScene = SpriteKitUIScene()
    @State private var debugOptions: SpriteView.DebugOptions = [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount]
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                preferredFramesPerSecond: 120,
                options: [.ignoresSiblingOrder],
                debugOptions: debugOptions
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    SpriteKitUI()
}

// MARK: - SpriteKit

class SpriteKitUIScene: SKScene {
    
    // MARK: didLoad
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .lightGray
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        createObjects()
    }
    
    // MARK: didMove
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        setupPhysicsBoundaries()
        setupMainCamera()
        createUI()
    }
    
    // MARK: Scene Setup
    func setupPhysicsBoundaries() {
        let physicalBorders = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody = physicalBorders
    }
    
    func setupMainCamera() {
        let camera = SKCameraNode()
        let viewSize = view?.bounds.size
        camera.xScale = (viewSize!.width / size.width)
        camera.yScale = (viewSize!.height / size.height)
        addChild(camera)
        scene?.camera = camera
    }
    
    // MARK: Create UI
    func createUI() {
        guard let camera = scene?.camera, let view = view else {
            return print("camera or view are not defined yet")
        }

        /// Palette
        let paletteTexture = SKTexture(imageNamed: "tools_container_black")
        let palette = SKSpriteNode(texture: paletteTexture)
        palette.name = "container"
        palette.zPosition = 1000
        camera.addChild(palette)
        
        /// Tools
        let materialTool = SKSpriteNode(imageNamed: "material_tool")
        materialTool.name = "material_tool"
        materialTool.position.y = 60
        materialTool.zPosition = 1001
        materialTool.color = SKColorWithRGB(255, g: 128, b: 128)
        palette.addChild(materialTool)
        
        let rotateTool = SKSpriteNode(imageNamed: "rotate_tool")
        rotateTool.name = "move_tool"
        rotateTool.position.y = 0
        rotateTool.zPosition = 1001
        palette.addChild(rotateTool)
        
        let moveTool = SKSpriteNode(imageNamed: "move_tool")
        moveTool.name = "move_tool"
        moveTool.position.y = -60
        moveTool.zPosition = 1001
        palette.addChild(moveTool)
        
        /// Update palette
        palette.size = palette.calculateAccumulatedFrame().size
        let padding: CGFloat = 20
        let edgeLeft = view.bounds.size.width * -0.5 + view.safeAreaInsets.left + padding
        let edgeBottom = view.bounds.size.height * -0.5 + view.safeAreaInsets.bottom + padding
        palette.position = CGPoint(x: edgeLeft + palette.frame.width/2, y: edgeBottom + palette.frame.height/2)
        palette.centerRect = setCenterRect(cornerWidth: 30, cornerHeight: 40, spriteNode: palette)
        
        /// Bounding box
        let boundingBoxWith = palette.size.width + 10
        let boundingBoxHeight = palette.size.height + 10
        let boundingBoxPath = CGPath(rect: CGRect(x: 0, y: 0, width: boundingBoxWith, height: boundingBoxHeight), transform: nil)
        var phase: CGFloat = 0
        let dashPattern: [CGFloat] = [10, 5]
        let dashedPath = boundingBoxPath.copy(dashingWithPhase: phase, lengths: dashPattern)
        
        let boundingBox = SKShapeNode(path: dashedPath)
        boundingBox.name = "bounding_box"
        boundingBox.lineWidth = 3
        boundingBox.strokeColor = .white
        boundingBox.glowWidth = 1
        boundingBox.fillColor = .clear
        boundingBox.position = CGPoint(x: -boundingBoxWith/2, y: -boundingBoxHeight/2)
        boundingBox.zPosition = 1002
        
        let incrementDashingPhaseAction = SKAction.run {
            phase -= 1
            let newDashedPath = boundingBoxPath.copy(dashingWithPhase: phase, lengths: dashPattern)
            boundingBox.path = newDashedPath
        }
        
        let waitAction = SKAction.wait(forDuration: 0.02)
        let sequenceAction = SKAction.sequence([incrementDashingPhaseAction, waitAction])
        let repeatForeverAction = SKAction.repeatForever(sequenceAction)
        boundingBox.run(repeatForeverAction)
        //palette.addChild(boundingBox)
        
        /// Shadows
        let containerShadow = SKSpriteNode(imageNamed: "container_shadow")
        let shadowExtent: CGFloat = 20
        containerShadow.size.height = palette.frame.size.height + shadowExtent * 2
        containerShadow.centerRect = setCenterRect(cornerWidth: 30, cornerHeight: 30, spriteNode: palette)
        containerShadow.zPosition = 999
        palette.addChild(containerShadow)
        
        /// Selector
        let selector = SKSpriteNode(imageNamed: "selector_dark")
        selector.name = "selector"
        selector.centerRect = setCenterRect(cornerWidth: 20, cornerHeight: 20, spriteNode: selector)
        selector.position = CGPoint(x: 0, y: 0)
        selector.zPosition = 2000
        let moveAction = SKEase.move(easeFunction: .curveTypeLinear, easeType: .easeTypeOut, time: 0.3, from: CGPoint(x: 0, y: -60), to: CGPoint(x: 0, y: 0))
        selector.run(moveAction)
        palette.addChild(selector)
    }
    
    // MARK: Create Objects
    func createObjects() {
        /// IKEA construction blocks
        let slimBlockTexture = SKTexture(imageNamed: "block_slim")
        let slimBlock = SKSpriteNode(texture: slimBlockTexture, size: slimBlockTexture.size())
        slimBlock.name = "slim_block"
        slimBlock.color = UIColor(hex: "DFB398") ?? .black
        slimBlock.colorBlendFactor = 1
        slimBlock.physicsBody = SKPhysicsBody(texture: slimBlockTexture, size: slimBlockTexture.size())
        addChild(slimBlock)
        
        let largeBlockTexture = SKTexture(imageNamed: "block_large")
        let largeBlock = SKSpriteNode(texture: largeBlockTexture, size: largeBlockTexture.size())
        largeBlock.name = "large_block"
        largeBlock.color = UIColor(hex: "EDC846") ?? .black
        largeBlock.colorBlendFactor = 1
        largeBlock.physicsBody = SKPhysicsBody(texture: largeBlockTexture, size: largeBlockTexture.size())
        addChild(largeBlock)
        
        let triangleBlockTexture = SKTexture(imageNamed: "block_triangle")
        let triangleBlock = SKSpriteNode(texture: triangleBlockTexture, size: triangleBlockTexture.size())
        triangleBlock.name = "triangle_block"
        triangleBlock.color = UIColor(hex: "D7414D") ?? .black
        triangleBlock.colorBlendFactor = 1
        triangleBlock.physicsBody = SKPhysicsBody(texture: triangleBlockTexture, size: triangleBlockTexture.size())
        addChild(triangleBlock)
        
        let circleBlockTexture = SKTexture(imageNamed: "block_circle")
        let circleBlock = SKSpriteNode(texture: circleBlockTexture, size: circleBlockTexture.size())
        circleBlock.name = "circle_block"
        circleBlock.color = UIColor(hex: "0190D6") ?? .black
        circleBlock.colorBlendFactor = 1
        circleBlock.physicsBody = SKPhysicsBody(texture: circleBlockTexture, size: circleBlockTexture.size())
        addChild(circleBlock)
        
        let archBlockTexture = SKTexture(imageNamed: "block_arch")
        let archBlock = SKSpriteNode(texture: archBlockTexture, size: archBlockTexture.size())
        archBlock.name = "arch_block"
        archBlock.color = UIColor(hex: "00AA64") ?? .black
        archBlock.colorBlendFactor = 1
        archBlock.physicsBody = SKPhysicsBody(texture: archBlockTexture, size: archBlockTexture.size())
        addChild(archBlock)
        
        /// Color wheel
        let myEffectNode = SKEffectNode()
        let hexColors = ["0190D6", "EDC846", "D7414D", "00AA64", "DFB398"]
        let colorWheel = ColorWheel(radius: 90, position: CGPoint(x: 0, y: 0), hexColors: hexColors)
        colorWheel.name = "color_wheel"
        myEffectNode.addChild(colorWheel)
        addChild(myEffectNode)
        myEffectNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 20])
        myEffectNode.filter = CIFilter(name: "CIDither", parameters: ["inputIntensity": 1])
        
        let rotationAction = SKAction.rotate(byAngle: 2 * .pi, duration: 2)
        myEffectNode.run(SKAction.repeatForever(rotationAction))
    }
    
    // MARK: Lifecyle
    
    override func didSimulatePhysics() {
        visualizeFrameOnce(nodeName: "color_wheel", in: scene!)
    }
    
    // MARK: Touch events
    var isSelectorTouched: Bool = false
    var intialSelectorPosition: CGPoint?
    var initialRulerTick: CGFloat?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        /// Prepare for dragging selector
        guard let selector = self.childNode(withName: "//selector"),
              let camera = scene?.camera else { return }
        
        let location = touch.location(in: camera)
        let touchedNode = atPoint(location)
        
        if touchedNode == selector {
            isSelectorTouched = true
            intialSelectorPosition = location
            initialRulerTick = location.y
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        /// Drag selector
        guard let selector = self.childNode(withName: "//selector") as? SKSpriteNode,
              let container = selector.parent,
              let camera = scene?.camera else { return }
        
        let location = touch.location(in: camera)
        
        if isSelectorTouched {
            let verticalDistance = location.y - (intialSelectorPosition?.y ?? 0.0)
            let maxY = container.frame.height / 2 - selector.frame.height / 2
            
            print("vertical distance: \(verticalDistance)")
            print("clamp: \(maxY)")
            
            if (location.y <= maxY) {
                selector.position.y += verticalDistance
            }
        }
        
        /// Ruler ticker
        if isSelectorTouched {
            let deltaTick = location.y - (initialRulerTick ?? 0.0)
            
            if abs(deltaTick) >= 10 {
                /// import AudioToolbox and play system sounds
                /// kudos to https://stackoverflow.com/a/65776719/420176
                /// list: https://iphonedev.wiki/AudioServices
                /// bookmarked: 1057, 1103, 1104, 1105, 1107, 1257, 1306
                AudioServicesPlaySystemSound(1306)
                initialRulerTick = location.y
            }
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        /// End dragging selector
        isSelectorTouched = false
        intialSelectorPosition = nil
        
        /// Reset ruler ticker
        initialRulerTick = nil
    }
}

// MARK: - Helper methods

/// Calculates the CGRect for the center part of a 9-slice sprite.
/// - Parameter cornerWidth: The width of the corner parts
/// - Parameter cornerHeight: The height of the corner parts
/// - Parameter sprite: The SKSpriteNode for which to calculate the center rect
/// - Returns: A CGRect representing the center rectangle for 9-slice scaling
func setCenterRect(cornerWidth: CGFloat, cornerHeight: CGFloat, spriteNode: SKSpriteNode) -> CGRect {
    guard let textureSize = spriteNode.texture?.size() else {
        return .zero
    }
    
    let totalWidth = textureSize.width
    let totalHeight = textureSize.height
    
    let centerSliceWidth = totalWidth - (cornerWidth * 2)
    let centerSliceHeight = totalHeight - (cornerHeight * 2)
    
    let centerSliceRect = CGRect(x: cornerWidth / totalWidth,
                      y: cornerHeight / totalHeight,
                      width: centerSliceWidth / totalWidth,
                      height: centerSliceHeight / totalHeight)
    
    return centerSliceRect
}

