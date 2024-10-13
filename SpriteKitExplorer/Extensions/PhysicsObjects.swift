//
//  PhysicsObjects.swift
//  SpriteKitExplorer
//
//  Created by Achraf Kassioui on 19/5/2024.
//

import SpriteKit

extension SKScene {
    
    // MARK: - Helpers
    
    func generateRandomName() -> String {
        return UUID().uuidString
    }
    
    func generateRandomColor() -> SKColor {
        let colors: [SKColor] = [.systemYellow, .systemRed, .systemBlue, .systemGreen]
        
        let randomColor = colors[Int.random(in: 0..<colors.count)]
        return randomColor
    }
    
    func removeThisNode(_ node: SKNode) {
        let duration: CGFloat = 0.1
        let removalAnimation = SKAction.group([
            SKAction.scale(to: 3, duration: duration),
            SKAction.fadeOut(withDuration: duration)
        ])
        
        node.run(removalAnimation) {
            node.removeAllActions()
            node.removeFromParent()
        }
    }
    
    func removeNodes(withName name: String) {
        let duration: CGFloat = 0.1
        let removalAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 3, duration: duration),
                SKAction.fadeOut(withDuration: duration)
            ]),
            SKAction.removeFromParent()
        ])
        
        self.enumerateChildNodes(withName: "//*\(name)*", using: {node, _ in
            node.run(removalAnimation)
            //node.removeAllActions()
        })
    }
    
    // MARK: - Physical Sprites
    
    enum SpriteShape {
        case roundedRectangle
        case circle
    }
    
    func spawnSpriteHere(shape: SpriteShape, sideLength: CGFloat, name: String, parent: SKNode, location: CGPoint) {
        switch shape {
        case .circle:
            let sprite = createBall(radius: sideLength/2, color: generateRandomColor(), name: name)
            sprite.position = location
            parent.addChild(sprite)
        case .roundedRectangle:
            let sprite = createRoundedRectangle(size: CGSize(width: sideLength, height: sideLength), color: generateRandomColor())
            sprite.position = location
            parent.addChild(sprite)
        }
    }
    
    func spawnSpriteHere(location: CGPoint, parent: SKNode, fromSwiftUI: Bool) {
        let sprite = SKSpriteNode(color: .systemRed, size: CGSize(width: 50, height: 50))
        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        setupPhysicsCategories(node: sprite, as: .sceneBody)
        
        if fromSwiftUI == true {
            sprite.position = convertPoint(fromView: location)
        } else if fromSwiftUI == false {
            sprite.position = location
        }
        parent.addChild(sprite)
    }
    
    func createRoundedRectangle(size: CGSize, color: SKColor, name: String? = nil, particleCollider: Bool? = nil, constrainInside: SKNode? = nil) -> SKNode {
        let square = SKSpriteNode(imageNamed: "rectangle-60-12-fill")
        square.name = name ?? nil
        square.size = size
        square.colorBlendFactor = 1
        square.color = color
        square.physicsBody = SKPhysicsBody(rectangleOf: size)
        setupPhysicsCategories(node: square, as: .sceneBody)
        if let rectangle = constrainInside {
            square.constraints = [createConstraintsWithRectangle(node: square, rectangle: rectangle)]
        }
        
        if particleCollider == true {
            let colliderField = SKFieldNode.radialGravityField()
            colliderField.strength = -0.4
            colliderField.region = SKRegion(size: size)
            setupPhysicsCategories(node: colliderField, as: .sceneParticleCollider)
            square.addChild(colliderField)
        }
        
        return square
    }
    
    func createBall(radius: CGFloat, color: SKColor, name: String, particleCollider: Bool? = nil, constrainInside: SKNode? = nil) -> SKNode {
        let circle = SKSpriteNode(imageNamed: "circle-30-fill")
        circle.name = "\(name)-\(UUID().uuidString)"
        circle.size = CGSize(width: radius*2, height: radius*2)
        circle.colorBlendFactor = 1
        circle.color = color
        circle.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        setupPhysicsCategories(node: circle, as: .sceneBody)
        if let rectangle = constrainInside {
            circle.constraints = [createConstraintsWithRectangle(node: circle, rectangle: rectangle)]
        }
        
        /// this will make the node collide with particles
        /// costly if there are too many balls
        if particleCollider == true {
            let colliderField = SKFieldNode.radialGravityField()
            colliderField.strength = -0.1
            colliderField.region = SKRegion(radius: Float(radius))
            setupPhysicsCategories(node: colliderField, as: .sceneParticleCollider)
            circle.addChild(colliderField)
        }
        
        return circle
    }
    
    // MARK: - Cloner
    
    func cloner(node: SKSpriteNode, amount: Int, randomPosition: Bool, parent: SKNode) {
        for _ in 1...amount {
            let clonedNode = node.copy() as! SKSpriteNode
            clonedNode.name = "\(node.name ?? "")-\(UUID().uuidString)"
            clonedNode.color = generateRandomColor()
            if randomPosition {
                clonedNode.position.x = CGFloat.random(in: -200...200)
                clonedNode.position.y = CGFloat.random(in: -400...400)
            }
            parent.addChild(clonedNode)
        }
    }
    
    // MARK: - Pinned
    
    func createPinnedObject(parent: SKNode) {
        let sprite = SKSpriteNode(color: .systemRed, size: CGSize(width: 60, height: 60))
        sprite.name = "flickable"
        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        sprite.physicsBody?.pinned = true
        sprite.physicsBody?.density = 1
        sprite.physicsBody?.categoryBitMask = BitMasks.sceneBody
        sprite.physicsBody?.collisionBitMask = BitMasks.sceneBody
        sprite.physicsBody?.fieldBitMask = BitMasks.sceneField
        sprite.position.y = 100
        parent.addChild(sprite)
    }
    
    // MARK: - Fields
    
    func createField(parent: SKNode) {
        let radius: Float = 100
        let minimumRadius: Float = 10
        
        let field = SKFieldNode.electricField()
        field.categoryBitMask = BitMasks.sceneField
        field.region = SKRegion(radius: radius)
        field.strength = 1
        field.minimumRadius = minimumRadius
        field.falloff = 0
        field.isUserInteractionEnabled = false
        field.position.y = 200
        parent.addChild(field)
        
        visualizeField(circleOfRadius: CGFloat(minimumRadius), text: "min radius", parent: field)
        visualizeField(circleOfRadius: CGFloat(radius), text: "Field", parent: field)
        
        let perimeter = SKShapeNode(circleOfRadius: CGFloat(radius))
        perimeter.lineWidth = 3
        perimeter.strokeColor = SKColor(white: 0, alpha: 0.8)
        perimeter.physicsBody = SKPhysicsBody(edgeLoopFrom: perimeter.path!)
        setupPhysicsCategories(node: perimeter, as: .sceneBody)
        field.addChild(perimeter)
    }
    
    // MARK: - Particles
    
    func createParticles(parent: SKNode) {
        if let particleEmitter = SKEmitterNode(fileNamed: "FireLarge") {
            particleEmitter.fieldBitMask = BitMasks.sceneField | BitMasks.sceneParticleCollider
            particleEmitter.particlePositionRange = CGVector(dx: 390, dy: 75)
            particleEmitter.position.y = -360
            particleEmitter.zPosition = 11
            particleEmitter.particleBlendMode = .subtract
            parent.addChild(particleEmitter)
        }
    }
    
}
