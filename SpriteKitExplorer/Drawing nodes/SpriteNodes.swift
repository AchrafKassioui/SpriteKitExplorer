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
        backgroundColor = .darkGray
    }
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        scene?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        physicsWorld.speed = 1
        physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        //setupCamera()
        let cameraNode = InertialCamera(view: view, scene: self)
        addChild(cameraNode)
        camera = cameraNode
        
        /// comment/uncomment to execute various examples
        //drawSprites()
        drawSpriteWithShadow()
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
    
    // MARK: - Texture filtering
    
    func drawSomeSprites() {
        
    }
    
    // MARK: - Shadow sprite
    
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

// MARK: - Core Image Filters

/// A list of Core Image filters to speed up code writing
///
/// To do:
/// - add default values
/// - add ranges
/// - add converters from SpriteKit data types to Core Image data types
struct MyFilters {
    static func dither(intensity: CGFloat) -> CIFilter {
        return CIFilter(name: "CIDither", parameters: ["inputIntensity": intensity])!
    }
    
    static func gaussianBlur(radius: CGFloat) -> CIFilter {
        return CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": radius])!
    }
    
    static func motionBlur(radius: CGFloat, angle: CGFloat) -> CIFilter {
        return CIFilter(name: "CIMotionBlur", parameters: ["inputRadius": radius, "inputAngle": angle])!
    }
    
    static func vignette(intensity: CGFloat) -> CIFilter {
        return CIFilter(name: "CIVignette", parameters: ["inputIntensity": intensity])!
    }
    
    static func bloom(intensity: CGFloat, radius: CGFloat) -> CIFilter {
        return CIFilter(name: "CIBloom", parameters: ["inputIntensity": intensity, "inputRadius": radius])!
    }
    
    static func pixellate(scale: CGFloat) -> CIFilter {
        return CIFilter(name: "CIPixellate", parameters: ["inputScale": scale])!
    }
    
    // transform the center parameter into CGPoint type,
    // then convert CGPoint to CIVector(x:y:) for CIFilter
    static func zoomBlur(amount: CGFloat, center: CIVector) -> CIFilter {
        return CIFilter(name: "CIZoomBlur", parameters: ["inputAmount": amount, "inputCenter": center])!
    }
    
    static func CMYKHalftone(width: CGFloat, angle: CGFloat, sharpness: CGFloat) -> CIFilter {
        return CIFilter(name: "CICMYKHalftone", parameters: ["inputWidth": width, "inputAngle": angle, "inputSharpness": sharpness])!
    }
    
    static func xRay() -> CIFilter {
        return CIFilter(name: "CIXRay")!
    }
    
    static func monochrome(intensity: CGFloat, color: CIColor) -> CIFilter {
        return CIFilter(name: "CIColorMonochrome", parameters: ["inputIntensity": intensity, "inputColor": color])!
    }
}



