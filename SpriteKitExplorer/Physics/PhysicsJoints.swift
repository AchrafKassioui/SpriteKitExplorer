//
//  PhysicsJoints.swift
//  SpriteKitExplorer
//
//  Created by Achraf Kassioui on 16/5/2024.
//

import SpriteKit

extension PhysicsPlaygroundScene {
    
    // MARK: Sliding Joint
    /**
     
     Unstable. Rewrite it.
     
     */
    
    func createSlidingJoint(in parent: SKNode) {
        /// link object
        let linkStart = SKShapeNode(rectOf: CGSize(width: 40, height: 40), cornerRadius: 7)
        linkStart.name = "flickable-springStart"
        linkStart.lineWidth = 0
        linkStart.fillColor = .systemRed
        linkStart.physicsBody = SKPhysicsBody(rectangleOf: linkStart.frame.size)
        setupPhysicsCategories(node: linkStart, as: .sceneBody)
        linkStart.constraints = [createSceneConstraints(node: linkStart, insideRect: boundaryForSceneBodies)]
        linkStart.position = CGPoint(x: 0, y: 0)
        linkStart.zPosition = 10
        parent.addChild(linkStart)
        
        let linkEnd = SKShapeNode(rectOf: CGSize(width: 40, height: 40), cornerRadius: 7)
        linkEnd.name = "flickable-springEnd"
        linkEnd.lineWidth = 0
        linkEnd.fillColor = .systemYellow
        linkEnd.physicsBody = SKPhysicsBody(rectangleOf: linkEnd.frame.size)
        setupPhysicsCategories(node: linkEnd, as: .sceneBody)
        linkEnd.constraints = [createSceneConstraints(node: linkEnd, insideRect: boundaryForSceneBodies)]
        linkEnd.position = CGPoint(x: 0, y: -150)
        linkEnd.zPosition = 10
        parent.addChild(linkEnd)
        
        let jointViz = SKShapeNode()
        jointViz.name = "jointLink"
        jointViz.lineWidth = 4
        jointViz.strokeColor = SKColor(white: 0, alpha: 0.8)
        jointViz.zPosition = 9
        parent.addChild(jointViz)
        
        /// sliding joint
        let slidingJoint = SKPhysicsJointSliding.joint(
            withBodyA: linkStart.physicsBody!,
            bodyB: linkEnd.physicsBody!,
            anchor: linkStart.position,
            axis: CGVector(dx: 0, dy: 100)
        )
        slidingJoint.shouldEnableLimits = true
        slidingJoint.lowerDistanceLimit = 50
        slidingJoint.upperDistanceLimit = 200
        physicsWorld.add(slidingJoint)
    }
    
    // MARK: Spring joint with fixed wheels
    
    func createSpringJointWithFixedWheels(in parent: SKNode) {
        let anchorSize = CGSize(width: 2, height: 20)
        let bodyRadius: CGFloat = 30
        let dotRadius: CGFloat = 2
        let margin: CGFloat = 4
        
        /// spring anchors
        let springStart = SKSpriteNode(color: .systemBlue, size: anchorSize)
        springStart.name = "flickable-anchor-A"
        springStart.physicsBody = SKPhysicsBody(rectangleOf: springStart.size)
        setupPhysicsCategories(node: springStart, as: .sceneBody)
        springStart.zPosition = 10
        parent.addChild(springStart)
        
        let springEnd = SKSpriteNode(color: .systemGreen, size: anchorSize)
        springEnd.name = "flickable-anchor-B"
        springEnd.physicsBody = SKPhysicsBody(rectangleOf: springEnd.size)
        setupPhysicsCategories(node: springEnd, as: .sceneBody)
        springEnd.position = CGPoint(x: 0, y: -150)
        springEnd.zPosition = 10
        parent.addChild(springEnd)
        
        /// line between spring anchors
        let jointLink = SKShapeNode()
        jointLink.name = "joint-link"
        parent.addChild(jointLink)
        
        /// spring joint
        let springJoint = SKPhysicsJointSpring.joint(
            withBodyA: springStart.physicsBody!,
            bodyB: springEnd.physicsBody!,
            anchorA: springStart.position,
            anchorB: springEnd.position
        )
        springJoint.frequency = 30
        springJoint.damping = 0.5
        physicsWorld.add(springJoint)
        
        /// bodies
        let wheel1 = SKShapeNode(circleOfRadius: 30)
        wheel1.name = "flickable"
        wheel1.strokeColor = SKColor(white: 0, alpha: 0.8)
        wheel1.fillColor = SKColor(white: 1, alpha: 0.3)
        wheel1.physicsBody = SKPhysicsBody(circleOfRadius: bodyRadius)
        setupPhysicsCategories(node: wheel1, as: .sceneBody)
        wheel1.physicsBody?.friction = 1
        parent.addChild(wheel1)
        
        let dot1 = SKShapeNode(circleOfRadius: dotRadius)
        dot1.lineWidth = 0
        dot1.fillColor = SKColor(white: 0, alpha: 0.8)
        dot1.position = CGPoint(x: 0, y: bodyRadius - dotRadius - margin)
        dot1.zPosition = 20
        wheel1.addChild(dot1)
        
        let wheel2 = SKShapeNode(circleOfRadius: 30)
        wheel2.name = "flickable"
        wheel2.strokeColor = SKColor(white: 0, alpha: 0.8)
        wheel2.fillColor = SKColor(white: 1, alpha: 0.3)
        wheel2.physicsBody = SKPhysicsBody(circleOfRadius: bodyRadius)
        setupPhysicsCategories(node: wheel2, as: .sceneBody)
        wheel2.physicsBody?.friction = 1
        wheel2.position = CGPoint(x: 0, y: -150)
        parent.addChild(wheel2)
        
        let dot2 = SKShapeNode(circleOfRadius: dotRadius)
        dot2.lineWidth = 0
        dot2.fillColor = SKColor(white: 0, alpha: 0.8)
        dot2.position = CGPoint(x: 0, y: -bodyRadius + dotRadius + margin)
        dot2.zPosition = 20
        wheel2.addChild(dot2)
        
        /// fixed joint that links the anchors with the bodies
        let fixedJointStart = SKPhysicsJointFixed.joint(withBodyA: springStart.physicsBody!, bodyB: wheel1.physicsBody!, anchor: wheel1.position)
        physicsWorld.add(fixedJointStart)
        
        let fixedJointEnd = SKPhysicsJointFixed.joint(withBodyA: springEnd.physicsBody!, bodyB: wheel2.physicsBody!, anchor: wheel2.position)
        physicsWorld.add(fixedJointEnd)
    }
    
    // MARK: Fixed joint with spinning wheels
    
    func createFixedJointWithSpinningWheels(in parent: SKNode) {
        let jointLength: CGFloat = 150
        let jointEndsSize = CGSize(width: 20, height: 20)
        
        let bodyRadius: CGFloat = 30
        let dotRadius: CGFloat = 2
        let margin: CGFloat = 4
        
        /// spring anchors
        let anchorA = SKShapeNode(rectOf: jointEndsSize, cornerRadius: 7)
        anchorA.name = "anchor-A"
        anchorA.lineWidth = 0
        anchorA.fillColor = .systemRed
        anchorA.physicsBody = SKPhysicsBody(rectangleOf: jointEndsSize)
        setupPhysicsCategories(node: anchorA, as: .sceneBody)
        anchorA.zPosition = 10
        parent.addChild(anchorA)
        
        let anchorB = SKShapeNode(rectOf: jointEndsSize, cornerRadius: 7)
        anchorB.name = "anchor-B"
        anchorB.lineWidth = 0
        anchorB.fillColor = .systemYellow
        anchorB.physicsBody = SKPhysicsBody(rectangleOf: jointEndsSize)
        setupPhysicsCategories(node: anchorB, as: .sceneBody)
        anchorB.position = CGPoint(x: 0, y: -jointLength)
        anchorB.zPosition = 10
        parent.addChild(anchorB)
        
        /// line between spring anchors
        let jointLink = SKShapeNode()
        jointLink.name = "joint-link"
        jointLink.strokeColor = SKColor(white: 0, alpha: 0.6)
        jointLink.lineWidth = 4
        jointLink.lineCap = .round
        parent.addChild(jointLink)
        
        /// the actual fixed joint
        let fixedJoint = SKPhysicsJointFixed.joint(
            withBodyA: anchorA.physicsBody!,
            bodyB: anchorB.physicsBody!,
            anchor: anchorA.position - anchorB.position
        )
        physicsWorld.add(fixedJoint)
        
        /// bodies to simulate collisions between the spring ends
        /// we attach the bodies to the spring ends using another joint of type Pin
        let wheel1 = SKShapeNode(circleOfRadius: bodyRadius)
        wheel1.name = "flickable"
        wheel1.strokeColor = SKColor(white: 0, alpha: 0.8)
        wheel1.fillColor = SKColor(white: 0, alpha: 0.3)
        wheel1.physicsBody = SKPhysicsBody(circleOfRadius: bodyRadius)
        setupPhysicsCategories(node: wheel1, as: .sceneBody)
        wheel1.physicsBody?.friction = 1
        wheel1.constraints = [createSceneConstraints(node: wheel1, insideRect: boundaryForSceneBodies)]
        parent.addChild(wheel1)
        
        let dot1 = SKShapeNode(circleOfRadius: dotRadius)
        dot1.lineWidth = 0
        dot1.fillColor = SKColor(white: 0, alpha: 0.8)
        dot1.position = CGPoint(x: 0, y: bodyRadius - dotRadius - margin)
        wheel1.addChild(dot1)
        
        let wheel2 = SKShapeNode(circleOfRadius: bodyRadius)
        wheel2.name = "flickable"
        wheel2.strokeColor = SKColor(white: 0, alpha: 0.8)
        wheel2.fillColor = SKColor(white: 0, alpha: 0.3)
        wheel2.physicsBody = SKPhysicsBody(circleOfRadius: bodyRadius)
        setupPhysicsCategories(node: wheel2, as: .sceneBody)
        wheel2.physicsBody?.friction = 1
        wheel2.constraints = [createSceneConstraints(node: wheel2, insideRect: boundaryForSceneBodies)]
        wheel2.position = CGPoint(x: 0, y: -jointLength)
        parent.addChild(wheel2)
        
        let dot2 = SKShapeNode(circleOfRadius: dotRadius)
        dot2.lineWidth = 0
        dot2.fillColor = SKColor(white: 0, alpha: 0.8)
        dot2.position = CGPoint(x: 0, y: -bodyRadius + dotRadius + margin)
        wheel2.addChild(dot2)
        
        /// rotating pin joint
        /**
         If the pin is prevented from spinning, and if the body to which the pin is attached is subject to high velocities, the simulation may become unstable.
         */
        let enableSpin: Bool = true
        let lowerAngleLimit: CGFloat = 0
        let upperAngleLimit: CGFloat = 0
        /**
         Rotation speed and friction torque work together. They create a motor.
         */
        let rotationSpeed: CGFloat = 5
        let frictionTorque: CGFloat = 10
        
        let pinJointStart = SKPhysicsJointPin.joint(withBodyA: anchorA.physicsBody!, bodyB: wheel1.physicsBody!, anchor: wheel1.position)
        pinJointStart.shouldEnableLimits = !enableSpin
        pinJointStart.upperAngleLimit = upperAngleLimit
        pinJointStart.lowerAngleLimit = lowerAngleLimit
        pinJointStart.rotationSpeed = rotationSpeed
        pinJointStart.frictionTorque = frictionTorque
        physicsWorld.add(pinJointStart)
        
        let pinJointEnd = SKPhysicsJointPin.joint(withBodyA: anchorB.physicsBody!, bodyB: wheel2.physicsBody!, anchor: wheel2.position)
        pinJointEnd.shouldEnableLimits = !enableSpin
        pinJointEnd.upperAngleLimit = upperAngleLimit
        pinJointEnd.lowerAngleLimit = lowerAngleLimit
        pinJointEnd.rotationSpeed = rotationSpeed
        pinJointEnd.frictionTorque = frictionTorque
        physicsWorld.add(pinJointEnd)
    }
    
    // MARK: Pin Joint
    
    func createPinJoint(in parent: SKNode) {
        let objectA = SKSpriteNode(color: .systemRed, size: CGSize(width: 100, height: 20))
        objectA.name = "flickable"
        objectA.physicsBody = SKPhysicsBody(rectangleOf: objectA.size)
        objectA.physicsBody?.isDynamic = true
        parent.addChild(objectA)
        
        let objectB = SKSpriteNode(color: .systemYellow, size: CGSize(width: 100, height: 20))
        objectB.name = "flickable"
        objectB.physicsBody = SKPhysicsBody(rectangleOf: objectB.size)
        objectB.position.y = 0
        parent.addChild(objectB)
        
        let springJoint = SKPhysicsJointPin.joint(
            withBodyA: objectA.physicsBody!,
            bodyB: objectB.physicsBody!,
            anchor: objectA.position
        )
        physicsWorld.add(springJoint)
    }
    
}
