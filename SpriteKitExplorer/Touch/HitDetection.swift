/**
 
 # Hit Detection in SpriteKit
 
 Hit detection is how to determine which node is present at some location in space.
 it is common to use hit detection to determine which node has the user touched.
 This file explores various hit detection strategies.
 
 Created: 25 March 2024
 Updated: 31 March 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct HitDetectionView: View {
    var myScene = HitDetectionScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS, .showsPhysics]
            )
            .ignoresSafeArea()
        }
    }
}

/// this is for Xcode live preview
#Preview {
    HitDetectionView()
}

// MARK: - Scene setup

class HitDetectionScene: SKScene, SKPhysicsContactDelegate {
    
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .gray
        physicsWorld.contactDelegate = self
        setupCamera()
        createSomeBodies()
        createTouchBody()
    }
    
    func setupCamera() {
        let camera = SKCameraNode()
        camera.name = "camera"
        let viewSize = view?.bounds.size
        camera.xScale = (viewSize!.width / size.width)
        camera.yScale = (viewSize!.height / size.height)
        addChild(camera)
        scene?.camera = camera
        camera.setScale(1)
    }
    
    func createSomeBodies() {
        let orangeRickyTexture = SKTexture(imageNamed: "orange-ricky")
        let orangeRicky = SKSpriteNode(texture: orangeRickyTexture, size: orangeRickyTexture.size())
        orangeRicky.name = "orange-ricky"
        orangeRicky.colorBlendFactor = 1
        orangeRicky.color = .systemOrange
        orangeRicky.alpha = 1
        orangeRicky.position = CGPoint(x: -10, y: -10)
        orangeRicky.zPosition = 10
        
        /// used later to do hit detection with physics body
        let physicsTextureSize = CGSize(
            width: orangeRickyTexture.size().width,
            height: orangeRickyTexture.size().height
        )
        orangeRicky.physicsBody = SKPhysicsBody(texture: orangeRickyTexture, size: physicsTextureSize)
        orangeRicky.physicsBody?.affectedByGravity = false
        orangeRicky.physicsBody?.angularDamping = 1
        orangeRicky.physicsBody?.collisionBitMask = 0
        orangeRicky.physicsBody?.contactTestBitMask = 1
        
        addChild(orangeRicky)
        
        let clevelandTexture = SKTexture(imageNamed: "cleveland")
        let cleveland = SKSpriteNode(texture: clevelandTexture, size: clevelandTexture.size())
        cleveland.name = "cleveland"
        cleveland.colorBlendFactor = 1
        cleveland.color = .systemGreen
        cleveland.position = CGPoint(x: 10, y: 10)
        cleveland.zPosition = 8
        
        let clevelandTextureSize = CGSize(
            width: clevelandTexture.size().width,
            height: clevelandTexture.size().height
        )
        cleveland.physicsBody = SKPhysicsBody(texture: clevelandTexture, size: clevelandTextureSize)
        cleveland.physicsBody?.affectedByGravity = false
        cleveland.physicsBody?.collisionBitMask = 0
        cleveland.physicsBody?.contactTestBitMask = 1
        
        addChild(cleveland)
        
        let rectangle = SKSpriteNode(color: SKColor.systemRed, size: CGSize(width: 240, height: 60))
        rectangle.name = "rectangle"
        rectangle.zRotation = .pi * 0.1
        rectangle.zPosition = 5
        
        rectangle.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 240, height: 60))
        rectangle.physicsBody?.affectedByGravity = false
        rectangle.physicsBody?.collisionBitMask = 0
        rectangle.physicsBody?.contactTestBitMask = 1
        
        addChild(rectangle)
        
        let pathPoints: [CGPoint] = [CGPoint(x: -50, y: -50), CGPoint(x: 0, y: 50), CGPoint(x: 50, y: -50)]
        let path = CGMutablePath()
        path.addLines(between: pathPoints)
        path.closeSubpath()
        
        let triangle = SKShapeNode(path: path)
        triangle.name = "triangle"
        triangle.strokeColor = .orange
        triangle.lineWidth = 3
        triangle.fillColor = SKColor(white: 1, alpha: 0.2)
        triangle.position = CGPoint(x: 0, y: -200)
        
        triangle.physicsBody = SKPhysicsBody(polygonFrom: path)
        triangle.physicsBody?.affectedByGravity = false
        triangle.physicsBody?.contactTestBitMask = 1
        
        addChild(triangle)
        
        let label = SKLabelNode(text: "Hit Detection")
        label.name = "label"
        label.verticalAlignmentMode = .center
        label.fontName = "Menlo-Bold"
        label.fontColor = SKColor(white: 1, alpha: 0.6)
        label.fontSize = 36
        label.zPosition = 30
        label.position = CGPoint(x: 0, y: 200)
        
        if let labelTexture = view?.texture(from: label) {
            label.physicsBody = SKPhysicsBody(texture: labelTexture, size: labelTexture.size())
        }
        label.physicsBody?.affectedByGravity = false
        label.physicsBody?.collisionBitMask = 0
        
        addChild(label)
    }
    
    // MARK: - Hit detection
    
    let unnamed: String = "\"unnamed\""
    
    /**
     
     # Bounding box hit detection
     
     Given a point in space, return the nodes whose bounding box, aka the accumulated frame, contains the point.
     Note that the accumulated frame of a node is axis aligned. It does not rotate with the node. For example, it expands to enclose a rotated node.
     Fully transparent or hidden nodes are not returned.
     This method is not suitable for precise hit detection of semi-transparent or non-rectangular looking entities.
     
     */
    func hitDetectionWithBoundingBox(location: CGPoint) {
        /// returns all nodes under the touch location
        /// The array returned by `nodes(at:)` is ordered from front to back
        /// The first element in the array is the node that visually appears on top at the touch location
        let touchedNodes = nodes(at: location)
        for node in touchedNodes {
            print("Bounding box of node named \(node.name ?? unnamed) has been touched")
        }
        
        /// returns the deepest node in the hierarchy (the "childest" node)
        /// if it finds nodes with the same parent, it returns the node with the largest z position
        let foremostNode = atPoint(location)
        print("The foremost found node is \(foremostNode.name ?? unnamed)")
    }
    
    /**
     
     # Physics based hit detection
     
     Relies on the shape created by SKPhysicsBody
     Get the first physics body found. There might or might not be other physics bodies at this location.
     This method returns only the first body found by the physics engine.
     
     */
    func hitDetectionWithBody(location: CGPoint) {
        guard let touchedBody = physicsWorld.body(at: location) else {
            print("No physics body found")
            return
        }
        
        print("Physics body with name \(touchedBody.node?.name ?? unnamed) found")
    }
    
    /**
     
     # Physics based hit detection
     
     Relies on the shape created by SKPhysicsBody
     Get all physical bodies found under the touch location.
     This method is effective, but it requires that the target node has an accurate physics body shape.
     
     */
    func hitDetectionWithEnumerateBodies(location: CGPoint) {
        var touchedBodies: [SKPhysicsBody] = []
        
        /// enumerate through all bodies at the touch location
        physicsWorld.enumerateBodies(at: location) { body, stop in
            touchedBodies.append(body)
            print("Physics body with name \(body.node?.name ?? self.unnamed) found at \(location)")
        }
        
        /// sort bodies by zPosition of their nodes (highest first)
        let sortedBodies = touchedBodies.sorted {
            guard let nodeA = $0.node, let nodeB = $1.node else { return false }
            return nodeA.zPosition > nodeB.zPosition
        }
        
        /// do somehting with the top-most body according to zPosition
        if let topBody = sortedBodies.first {
            print("Top-most physics body is \(topBody.node?.name ?? unnamed) and has zPosition \(topBody.node?.zPosition ?? 0)")
            
            topBody.applyAngularImpulse(1)
        }
    }
    
    /**
     
     # Transparency based hit detection
     
     This strategy uses Core Graphics to analyize the texture of a node.
     It determines whether the pixel at the touch location has an alpha value above some threshold.
     
     This method assumes it can access the texture of the touched node:
     - On nodes that are *not* of type SKSpriteNode, we try to generate an SKTexture with the `texture(from:)` method of UIView.
     - On nodes of type SKSpriteNode, we use the attached SKTexture. Sprite nodes that were created without an explicit texture are ignored.
     
     If a texture has been succesfully retrieved, we read the pixel information with Core Graphics.
     The function returns true if the pixel alpha value is above the threshold.
     
     */
    /// this function should be rewritten to take a CGPoint instead of a UITouch
    func hitDetectionWithTransparency(_ touch: UITouch) {
        let touchLocation = touch.location(in: self)
        let touchedNodes = nodes(at: touchLocation)
        
        for node in touchedNodes {
            if isTouchOnTransparentArea(touch: touch, node: node) {
                print("Node named \(node.name ?? unnamed) has been touched")
            }
        }
    }
    
    /// this function should be rewritten to not take a UITouch
    func isTouchOnTransparentArea(touch: UITouch, node: SKNode, threshold: CGFloat = 0.1) -> Bool {
        let locationInNode = touch.location(in: node)
        
        /// try texture based on node type
        let texture: SKTexture?
        if let spriteNode = node as? SKSpriteNode {
            texture = spriteNode.texture
        } else {
            /// render the node to a texture if it's not an SKSpriteNode
            texture = self.view?.texture(from: node)
        }
        
        guard let cgImage = texture?.cgImage() else {
            print("A node was touched but no texture could be generated")
            return false
        }
        
        let textureSize = texture?.size() ?? CGSize.zero
        let scaleFactor = CGFloat(cgImage.width) / textureSize.width
        
        /// adjust the touch point to texture coordinates, flipping the Y axis
        let touchPointInTexture = CGPoint(
            x: (locationInNode.x + textureSize.width / 2) * scaleFactor,
            /// flip Y axis
            y: (textureSize.height / 2 - locationInNode.y) * scaleFactor
        )
        
        /// ensure the touch point is within texture bounds
        guard touchPointInTexture.x >= 0, touchPointInTexture.x < CGFloat(cgImage.width),
              touchPointInTexture.y >= 0, touchPointInTexture.y < CGFloat(cgImage.height) else {
            return false
        }
        
        guard let provider = cgImage.dataProvider, let pixelData = provider.data else { return false }
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let pixelInfo: Int = (cgImage.width * Int(touchPointInTexture.y) + Int(touchPointInTexture.x)) * 4
        
        let alpha = CGFloat(data[pixelInfo + 3]) / 255.0
        
        return alpha > threshold
    }
    
    // MARK: - Helpers
    
    /**
     
     These methods help with visualization and debugging.
     We create a circle that follows touch location.
     The circle visualize the touched area, and is used to test contact with other physics bodies.
     
     */
    func createTouchBody() {
        let touchCircle = SKShapeNode(circleOfRadius: 10)
        touchCircle.name = "touch-circle"
        touchCircle.fillColor = .white
        touchCircle.zPosition = 20
        touchCircle.position = CGPoint(x: 0, y: 300)
        
        touchCircle.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        touchCircle.physicsBody?.isDynamic = false
        touchCircle.physicsBody?.contactTestBitMask = 1
        
        addChild(touchCircle)
    }
    
    func followTouch(_ touch: UITouch) {
        let location = touch.location(in: self)
        guard let touchCircle = childNode(withName: "touch-circle") as? SKShapeNode else { return }
        
        let newPath = CGPath(
            ellipseIn: CGRect(
                x: -touch.majorRadius,
                y: -touch.majorRadius,
                width: touch.majorRadius * 2,
                height: touch.majorRadius * 2
            ),
            transform: nil
        )
        touchCircle.path = newPath
        touchCircle.position = location
        
        touchCircle.physicsBody = SKPhysicsBody(circleOfRadius: touch.majorRadius)
        touchCircle.physicsBody?.isDynamic = false
        touchCircle.physicsBody?.contactTestBitMask = 1
    }
    
    func resetFollowTouch() {
        guard let touchCircle = childNode(withName: "touch-circle") as? SKShapeNode else { return }
        let newRadius: CGFloat = 10
        let newPath = CGPath(ellipseIn: CGRect(x: -newRadius, y: -newRadius, width: newRadius*2, height: newRadius*2), transform: nil)
        touchCircle.path = newPath
        
        touchCircle.physicsBody = SKPhysicsBody(circleOfRadius: newRadius)
        touchCircle.physicsBody?.isDynamic = false
        touchCircle.physicsBody?.contactTestBitMask = 1
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var otherNode: SKNode?
        
        /// determine which node is not the "touchPoint" and set it to otherNode
        if contact.bodyA.node?.name == "touch-circle" {
            otherNode = contact.bodyB.node
            print("Contacted node has name \(otherNode?.name ?? unnamed)")
        } else if contact.bodyB.node?.name == "touch-circle" {
            otherNode = contact.bodyA.node
            print("Contacted node has name \(otherNode?.name ?? unnamed)")
        }
    }
    
    // MARK: - Touch events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            /// we need a point specified in the scene's coordinate system
            let touchLocation = touch.location(in: self)
            
            /// replace the function with 1 of the 4 hit detection strategies above
            hitDetectionWithBoundingBox(location: touchLocation)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            followTouch(touch)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetFollowTouch()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
