/**
 
 # Dragging Nodes
 
 Classes to create SpriteKit nodes that can be dragged with touch.
 
 Achraf Kassioui
 Created: 13 June 2024
 Updated: 13 June 2024
 
 */

import SwiftUI
import SpriteKit
import GameplayKit

// MARK: - With GKAgent

/// I wanted to implement dragging using GameplayKit Agent behavior.
/// Unfinished.
class SeekingSprite: SKSpriteNode, GKAgentDelegate {
    
    var agent: GKAgent2D!
    var targetAgent: GKAgent2D!
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - With Velocity

class DraggableSpriteWithVelocity: SKSpriteNode {
    
    // MARK: Properties and Init
    
    var spriteColor: SKColor
    var draggingColor: SKColor
    var isDragging = false {
        didSet {
            if isDragging {
                self.color = .systemRed
            } else {
                self.color = spriteColor
            }
        }
    }
    
    var startPosition: CGPoint = .zero
    
    // MARK: Init
    
    init(texture: SKTexture?, color: SKColor, size: CGSize, draggingColor: SKColor = .clear) {
        self.spriteColor = color
        self.draggingColor = draggingColor
        super.init(texture: texture, color: self.spriteColor, size: size)
        self.colorBlendFactor = 1
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Update
    
    /// This function is necessary so the node stays put after a touch move if the touch input is till active
    /// Must be called from the scene update loop
    func update(currentTime: TimeInterval) {
        if isDragging, currentTime - previousTimestamp > movementThreshold {
            if let body = self.physicsBody {
                body.velocity = .zero
                body.angularVelocity = 0
            }
        }
    }
    
    // MARK: Touch Events
    
    private var previousTimestamp: TimeInterval = 0
    private let movementThreshold: TimeInterval = 0.05
    
    enum PhysicsProperties {
        case dynamic
        case affectedByGravity
        case density
        case mass
        case charge
        case velocity
        case angularVelocity
        case collisionBitMask
        case fieldBitMask
    }
    
    private var originalPhysicsProperties: [PhysicsProperties: Any] = [:]
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        for touch in touches {
            guard let body = self.physicsBody else {
                print("DraggableSpriteWithPhysics: sprite has no physics body")
                return
            }
            
            /// Prepare for dragging
            isDragging = true
            startPosition = self.position
            previousTimestamp = touch.timestamp
            
            
            /// Store physics body properties
            originalPhysicsProperties = [
                .dynamic: body.isDynamic,
                .affectedByGravity: body.affectedByGravity,
                .density: body.density,
                .mass: body.mass,
                .charge: body.charge,
                .collisionBitMask: body.collisionBitMask,
                .fieldBitMask: body.fieldBitMask
            ]
            
            /// Apply physics properties suitable for dragging
            body.affectedByGravity = false
            body.velocity = .zero
            body.collisionBitMask = 0
            body.fieldBitMask = 0
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        for touch in touches {
            guard let parent = self.parent, let body = self.physicsBody, isDragging == true else {
                return
            }
            
            let touchLocation = touch.location(in: parent)
            let dx = touchLocation.x - touch.previousLocation(in: parent).x
            let dy = touchLocation.y - touch.previousLocation(in: parent).y
            let dt = touch.timestamp - previousTimestamp
            let velocity = CGVector(dx: dx/dt, dy: dy/dt)
            body.velocity = velocity / (self.scene?.physicsWorld.speed ?? 1)
            
            previousTimestamp = touch.timestamp
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        /// Don't go further if the node isn't physical
        guard let body = self.physicsBody else { return }
        
        /// Node is no longer dragged
        isDragging = false
        
        /// Restore physics body properties
        body.affectedByGravity = originalPhysicsProperties[.affectedByGravity] as? Bool ?? true
        //body.isDynamic = originalPhysicsProperties[.dynamic] as? Bool ?? true
        body.collisionBitMask = originalPhysicsProperties[.collisionBitMask] as? UInt32 ?? 0xFFFFFFFF
        body.fieldBitMask = originalPhysicsProperties[.fieldBitMask] as? UInt32 ?? 0xFFFFFFFF
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        isDragging = false
        self.position = startPosition
    }
}

// MARK: - With Position

class DraggableSprite: SKSpriteNode {
    
    init(texture: SKTexture?, color: SKColor, size: CGSize, delay: CGFloat = 0) {
        self.delay = delay
        super.init(texture: texture, color: color, size: size)
        self.colorBlendFactor = 1
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isDragging = false
    var delay: CGFloat = 0
    var touchOffset: CGPoint = .zero
    var startPosition: CGPoint = .zero
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        for touch in touches {
            guard let parent = self.parent else { return }
            let touchLocation = touch.location(in: parent)
            isDragging = true
            startPosition = self.position
            touchOffset = touchLocation - self.position
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        for touch in touches {
            guard let parent = self.parent else { return }
            
            if isDragging == true {
                let touchLocation = touch.location(in: parent)
                let newPosition = touchLocation - touchOffset
                self.position = newPosition
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        isDragging = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        isDragging = false
        self.position = startPosition
    }
    
}
