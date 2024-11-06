/**
 
 # Rotation Controller
 
 Implementing a one finger rotation controller with SpriteKit. Take two. 🎬
 
 Achraf Kassioui
 Created: 16 October 2024
 Updated: 16 October 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - Live preview

struct RotationControllerView: View {
    
    var body: some View {
        SpriteView(
            scene: RotationControllerScene(),
            preferredFramesPerSecond: 120,
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
            debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS]
        )
        .ignoresSafeArea()
    }
}

#Preview {
    RotationControllerView()
}

// MARK: - Demo Scene

class RotationControllerScene: SKScene {
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        backgroundColor = SKColor.gray
        
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.lock = false
        camera = inertialCamera
        addChild(inertialCamera)
        
        Task {
            let gridImage = await generateGridTexture(cellSize: 50, rows: 20, cols: 10, linesColor: SKColor(white: 1, alpha: 0.2))
            
            await MainActor.run {
                let backgroundSprite = SKSpriteNode(texture: SKTexture(image: gridImage))
                addChild(backgroundSprite)
            }
        }
        
        addRotationController(view: view)
    }
    
    func addRotationController(view: SKView) {
        let rotationController = RotationController(view: view, radius: 90)
        rotationController.zPosition = 10
        rotationController.position.y = -view.bounds.height*0.5 + view.safeAreaInsets.bottom + rotationController.frame.height*0.5
        rotationController.name = "rotationController"
        camera?.addChild(rotationController)
        
        let shadowTexture = generateShadowTexture(
            width: rotationController.frame.width,
            height: rotationController.frame.height,
            cornerRadius: rotationController.wheelRadius,
            shadowOffset: CGSize(width: 0, height: 0),
            shadowBlurRadius: 10,
            shadowColor: SKColor(white: 0, alpha: 0.3)
        )
        let shadowSprite = SKSpriteNode(texture: shadowTexture)
        shadowSprite.blendMode = .multiplyAlpha
        shadowSprite.zPosition = -1
        rotationController.addChild(shadowSprite)
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let inerterialCamera = camera as? InertialCamera {
            inerterialCamera.updateInertia()
        }
        
        enumerateChildNodes(withName: "//rotationController") { node, _ in
            if let rotationController = node as? RotationController {
                rotationController.update(currentTime)
            }
        }
    }
    
    var activeTouchesOnRotationController: Set<UITouch> = []
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            _ = nodes(at: location)
            
            if let inertialCamera = camera as? InertialCamera {
                inertialCamera.stopInertia()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {

        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {

        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
}

// MARK: - Rotation Controller Class

protocol RotationControllerDelegate: AnyObject {
    func rotationControllerIsTouched(touched: Bool)
    func rotationControllerWillRotate(zRotation: CGFloat)
    func rotationControllerDidRotate(zRotation: CGFloat)
}

class RotationController: SKSpriteNode {
    
    weak var view: SKView?
    weak var delegate: RotationControllerDelegate?
    private var noGoZone: SKShapeNode?
    
    /**
     
     # Settings
     
     */
    var strokeColor = SKColor(white: 0, alpha: 0.5)
    var fillColor = SKColor.lightGray
    var innerFillColor = SKColor.gray
    var accentColor = SKColor(red: 247/255, green: 208/255, blue: 84/255, alpha: 1)
    var wheelRadius: CGFloat
    
    // MARK: Init
    
    init(view: SKView, radius: CGFloat) {
        self.view = view
        self.wheelRadius = radius
        
        super.init(texture: nil, color: .clear, size: CGSize(width: radius*2, height: radius*2))
        self.isUserInteractionEnabled = true
        
        if let texture = getTextureFromShape(view: view) {
            self.texture = texture
            self.size = texture.size()
        }
    }
    
    // MARK: Styling
    
    func getTextureFromShape(view: SKView) -> SKTexture? {
        // Define the outer circle (wheel)
        let wheelPath = CGMutablePath()
        wheelPath.addArc(center: .zero, radius: self.wheelRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
        wheelPath.closeSubpath()
        
        // Define the inner circle (axle) to "cut out"
        let axlePath = CGMutablePath()
        axlePath.addArc(center: .zero, radius: 26, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
        axlePath.closeSubpath()
        
        // Combine the paths to make a ring (outer minus inner)
        let combinedPath = CGMutablePath()
        combinedPath.addPath(wheelPath)    // Add the outer circle
        combinedPath.addPath(axlePath, transform: .identity) // Add the inner circle with no transformation
        
        // Create the wheel shape node from the combined path (a ring)
        let wheel = SKShapeNode(path: combinedPath)
        wheel.lineWidth = 1
        wheel.strokeColor = self.strokeColor
        wheel.fillColor = self.fillColor
        
        // Add the handle (or other visual elements)
        let handle = SKShapeNode(rectOf: CGSize(width: 10, height: 52), cornerRadius: 3)
        handle.fillColor = self.accentColor
        handle.strokeColor = self.strokeColor
        handle.lineWidth = 1
        handle.position.y = wheelRadius - handle.frame.height / 2 - 3
        wheel.addChild(handle)
        
        self.noGoZone = wheel // The no-go zone can still be the same, if needed
        
        // Render the node (with the ring) into a texture
        let texture = view.texture(from: wheel)
        return texture
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Protocol
    
    var isTouched = false {
        didSet {
            delegate?.rotationControllerIsTouched(touched: isTouched)
        }
    }
    
    override var zRotation: CGFloat {
        willSet {
            delegate?.rotationControllerWillRotate(zRotation: self.zRotation)
        }
        didSet {
            delegate?.rotationControllerDidRotate(zRotation: self.zRotation)
        }
    }
    
    // MARK: API
    
    private func calculateRotationAngle(start: CGPoint, end: CGPoint) -> CGFloat {
        let center = self.position
        let startVector = CGVector(dx: start.x - center.x, dy: start.y - center.y)
        let endVector = CGVector(dx: end.x - center.x, dy: end.y - center.y)
        
        let angleDifference = atan2(startVector.dy * endVector.dx - startVector.dx * endVector.dy,
                                    startVector.dx * endVector.dx + startVector.dy * endVector.dy)
        /// Inverted to match the natural touch rotation direction
        return -angleDifference
    }
    
    func isInsideNoGoZone(touch: UITouch) {
        guard let parent = self.parent, let noGoZone = noGoZone else { return }
        
        let positionInSelf = touch.location(in: self)
        let positionInParent = touch.location(in: parent)
        
        /// Check if the touch is inside the no-go zone
        if noGoZone.contains(positionInSelf) {
            self.previousTouchPosition = positionInParent
            return
        }
    }
    
    // MARK: Update
    
    var angularVelocityFactor: CGFloat = 0.99
    
    func update(_ currentTime: TimeInterval) {
        
        angularVelocity *= angularVelocityFactor
        
        if (abs(angularVelocity) < 0.001) {
            angularVelocity = 0
        } else {
            self.zRotation += angularVelocity
        }
        
    }
    
    // MARK: Touch Events
    
    private var previousTouchPosition: CGPoint = .zero
    private var previousTouchTime: TimeInterval = 0
    private var previousAngle: CGFloat = 0
    private var angularVelocity: CGFloat = 0
    private var minimumDurationForInertia: Double = 0.02
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            isTouched = true
            
            if let parent = self.parent {
                angularVelocity = 0
                previousTouchPosition = touch.location(in: parent)
                previousTouchTime = touch.timestamp
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, let parent = self.parent {
            
            /// Update rotation
            let touchLocation = touch.location(in: parent)
            let angle = calculateRotationAngle(start: previousTouchPosition, end: touchLocation)
            self.zRotation += angle
            
            /// Reset position and time state
            previousTouchTime = touch.timestamp
            previousTouchPosition = touchLocation
            previousAngle = angle
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, let parent = self.parent {
            isTouched = false
            
            let distance = touch.location(in: parent) - previousTouchPosition
            let deltaTime = touch.timestamp - previousTouchTime
            let velocity = distance.length() / deltaTime
            let direction: CGFloat = previousAngle >= 0 ? 1 : -1
            angularVelocity = direction * velocity/1000
            
        }
    }
    
}
