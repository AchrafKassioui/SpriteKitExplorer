/**
 
 # Physics Joints Playground
 
 Achraf Kassioui
 Created 7 November 2024
 updated 7 November 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

struct PhysicsJointsView: View {
    var myScene = PhysicsJointsScene()
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene
                ,debugOptions: [.showsFPS, .showsNodeCount, .showsPhysics]
            )
            .ignoresSafeArea()
        }
        .background(Color(SKColor.black))
    }
}

#Preview {
    PhysicsJointsView()
}

class PhysicsJointsScene: SKScene {
    
    // MARK: Scene Setup
    
    let fillColor = SKColor(white: 0, alpha: 0.3)
    var joints = [SKPhysicsJoint]()
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        physicsWorld.gravity = CGVector(dx: 0, dy: -10)
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.speed = 1
        
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.lockRotation = true
        inertialCamera.doubleTapToReset = false
        inertialCamera.zPosition = 1000
        self.camera = inertialCamera
        addChild(inertialCamera)
    
        createGridWithJoints()
        createGridNodesUI()
    }
    
    // MARK: Many Fixed Joints
    
    var gridNodes: [[SKSpriteNode]] = []
    
    func touchGridNodes(_ touch: UITouch) {
        let touchLocation = touch.location(in: self)
        let touchedNode = self.atPoint(touchLocation)
        if let buttonName = touchedNode.name {
            switch buttonName {
            case "buttonA":
                for row in gridNodes {
                    for node in row {
                        node.physicsBody?.applyImpulse(CGVector(dx: -1, dy: 10))
                    }
                }
            case "buttonB":
                for row in gridNodes {
                    for node in row {
                        node.physicsBody?.applyImpulse(CGVector(dx: 1, dy: 10))
                    }
                }
            default:
                break
            }
        }
    }
    
    func createGridNodesUI() {
        let buttonA = SKShapeNode(rectOf: CGSize(width: 100, height: 50), cornerRadius: 10)
        buttonA.name = "buttonA"
        buttonA.position = CGPoint(x: -60, y: -350)
        buttonA.fillColor = fillColor
        buttonA.strokeColor = SKColor(white: 0, alpha: 0.6)
        camera?.addChild(buttonA)
        
        let labelA = SKLabelNode(text: "Left")
        labelA.name = "buttonA"
        labelA.fontName = "Menlo-Bold"
        labelA.fontSize = 17
        labelA.fontColor = SKColor(white: 1, alpha: 1)
        labelA.verticalAlignmentMode = .center
        labelA.horizontalAlignmentMode = .center
        buttonA.addChild(labelA)
        
        let buttonB = SKShapeNode(rectOf: CGSize(width: 100, height: 50), cornerRadius: 10)
        buttonB.name = "buttonB"
        buttonB.position = CGPoint(x: 60, y: -350)
        buttonB.fillColor = fillColor
        buttonB.strokeColor = SKColor(white: 0, alpha: 0.6)
        camera?.addChild(buttonB)
        
        let labelB = SKLabelNode(text: "Right")
        labelB.name = "buttonB"
        labelB.fontName = "Menlo-Bold"
        labelB.fontSize = 17
        labelB.fontColor = SKColor(white: 1, alpha: 1)
        labelB.verticalAlignmentMode = .center
        labelB.horizontalAlignmentMode = .center
        buttonB.addChild(labelB)
    }
    
    func createGridWithJoints() {
        
        let gridOrigin = CGPoint(x: -100, y: 50)
        let rows: Int = 10
        let cols: Int = 6
        let spacing: CGFloat = 20
        let nodeSize: CGFloat = 20
        let useSpringJoints: Bool = false
        
        let frequency: CGFloat = 10
        let damping: CGFloat = 1
        
        // Create nodes for a grid and position them with spacing and specified offset
        for row in 0..<rows {
            var rowNodes: [SKSpriteNode] = []
            for col in 0..<cols {
                let node = SKSpriteNode(color: fillColor, size: CGSize(width: nodeSize, height: nodeSize))
                // Calculate position with spacing and specified offset
                node.position = CGPoint(
                    x: gridOrigin.x + CGFloat(col) * (nodeSize + spacing),
                    y: gridOrigin.y + CGFloat(row) * (nodeSize + spacing)
                )
                node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
                node.physicsBody?.restitution = 1
                addChild(node)
                rowNodes.append(node)
            }
            gridNodes.append(rowNodes)
        }
        
        // Create joints between adjacent nodes
        for row in 0..<rows {
            for col in 0..<cols {
                let currentNode = gridNodes[row][col]
                
                // Connect to the node on the left
                if col > 0 {
                    let leftNode = gridNodes[row][col - 1]
                    
                    if useSpringJoints {
                        let springJoint = SKPhysicsJointSpring.joint(
                            withBodyA: currentNode.physicsBody!,
                            bodyB: leftNode.physicsBody!,
                            anchorA: currentNode.position,
                            anchorB: leftNode.position
                        )
                        springJoint.frequency = frequency
                        springJoint.damping = damping
                        physicsWorld.add(springJoint)
                    } else {
                        let midpointX = (currentNode.position.x + leftNode.position.x) / 2 - 20
                        let midpointY = (currentNode.position.y + leftNode.position.y) / 2
                        let midpoint = CGPoint(x: midpointX, y: midpointY)
                        
                        let fixedJoint = SKPhysicsJointFixed.joint(
                            withBodyA: currentNode.physicsBody!,
                            bodyB: leftNode.physicsBody!,
                            anchor: midpoint
                        )
                        physicsWorld.add(fixedJoint)
                    }
                }
                
                // Connect to the node above
                if row > 0 {
                    let topNode = gridNodes[row - 1][col]
                    
                    if useSpringJoints {
                        let springJoint = SKPhysicsJointSpring.joint(
                            withBodyA: currentNode.physicsBody!,
                            bodyB: topNode.physicsBody!,
                            anchorA: currentNode.position,
                            anchorB: topNode.position
                        )
                        springJoint.frequency = frequency
                        springJoint.damping = damping
                        physicsWorld.add(springJoint)
                    } else {
                        let midpointX = (currentNode.position.x + topNode.position.x) / 2
                        let midpointY = (currentNode.position.y + topNode.position.y) / 2
                        let midpoint = CGPoint(x: midpointX, y: midpointY)
                        
                        let fixedJoint = SKPhysicsJointFixed.joint(
                            withBodyA: currentNode.physicsBody!,
                            bodyB: topNode.physicsBody!,
                            anchor: midpoint
                        )
                        physicsWorld.add(fixedJoint)
                    }
                }
            }
        }
    }
    
    // MARK: Fixed Joints
    
    func createFixedJoints() {
        let rectangle = SKSpriteNode(color: fillColor, size: CGSize(width: 60, height: 60))
        rectangle.name = "sprite"
        rectangle.position = CGPoint(x: -150, y: 0)
        rectangle.physicsBody = SKPhysicsBody(rectangleOf: rectangle.size)
        addChild(rectangle)
        
        let circle = SKShapeNode(circleOfRadius: 30)
        circle.name = "shape"
        circle.position = CGPoint(x: 50, y: 0)
        circle.lineWidth = 0
        circle.fillColor = fillColor
        circle.physicsBody = SKPhysicsBody(circleOfRadius: 30)
        addChild(circle)
        
        let label = SKLabelNode(text: "Joints")
        label.position = CGPoint(x: 0, y: 100)
        label.fontName = "MenloBold"
        label.fontSize = 24
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.physicsBody = SKPhysicsBody(rectangleOf: label.frame.size)
        addChild(label)
        
        let ground = SKSpriteNode(color: .black, size: CGSize(width: 1000, height: 10))
        ground.position.y = -400
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        addChild(ground)
        
        let joint1 = SKPhysicsJointFixed.joint(
            withBodyA: rectangle.physicsBody!,
            bodyB: circle.physicsBody!,
            anchor: CGPoint(x: rectangle.position.x, y: rectangle.position.y + rectangle.size.height / 2)
        )
        joints.append(joint1)
        physicsWorld.add(joint1)
        
        let joint2 = SKPhysicsJointFixed.joint(
            withBodyA: rectangle.physicsBody!,
            bodyB: label.physicsBody!,
            anchor: rectangle.position
        )
        joints.append(joint2)
        physicsWorld.add(joint2)
        
        let joint3 = SKPhysicsJointFixed.joint(
            withBodyA: circle.physicsBody!,
            bodyB: label.physicsBody!,
            anchor: circle.position
        )
        joints.append(joint3)
        physicsWorld.add(joint3)
    }
    
    // MARK: Update
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = self.camera as? InertialCamera {
            inertialCamera.update()
        }
    }
    
    // MARK: Touch
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let inertialCamera = self.camera as? InertialCamera {
            inertialCamera.stopInertia()
        }
        for touch in touches {
            touchGridNodes(touch)
        }
    }
}
