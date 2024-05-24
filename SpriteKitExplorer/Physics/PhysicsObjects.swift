//
//  PhysicsObjects.swift
//  SpriteKitExplorer
//
//  Created by Achraf Kassioui on 19/5/2024.
//

import SpriteKit

extension PhysicsPlaygroundScene {
    
    // MARK: - Objects
    
    func getRandomColor() -> SKColor {
        let colors: [SKColor] = [.systemYellow, .systemRed, .systemBlue, .systemGreen]
        
        let randomColor = colors[Int.random(in: 0..<colors.count)]
        return randomColor
    }
    
    func createSquare(size: CGSize, color: SKColor, name: String, particleCollider: Bool) -> SKNode {
        let square = SKSpriteNode(imageNamed: "rectangle-60-12-fill")
        square.name = "\(name)-\(UUID().uuidString)"
        square.size = size
        square.colorBlendFactor = 1
        square.color = getRandomColor()
        square.physicsBody = SKPhysicsBody(rectangleOf: size)
        setupPhysicsCategories(node: square, as: .sceneBody)
        square.constraints = [createSceneConstraints(node: square, insideRect: boundaryForSceneBodies)]
        
        if particleCollider {
            let colliderField = SKFieldNode.radialGravityField()
            colliderField.strength = -0.4
            colliderField.region = SKRegion(size: size)
            setupPhysicsCategories(node: colliderField, as: .sceneParticleCollider)
            square.addChild(colliderField)
        }
        
        return square
    }
    
    func createBall(radius: CGFloat, color: SKColor, name: String, particleCollider: Bool) -> SKNode {
        let circle = SKSpriteNode(imageNamed: "circle-30-fill")
        circle.name = "\(name)-\(UUID().uuidString)"
        circle.size = CGSize(width: radius*2, height: radius*2)
        circle.colorBlendFactor = 1
        circle.color = color
        circle.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        setupPhysicsCategories(node: circle, as: .sceneBody)
        circle.constraints = [createSceneConstraints(node: circle, insideRect: boundaryForSceneBodies)]
        
        /// this will make the node collide with particles
        /// costly if there are too many balls
        if particleCollider {
            let colliderField = SKFieldNode.radialGravityField()
            colliderField.strength = -0.4
            colliderField.region = SKRegion(radius: Float(radius))
            setupPhysicsCategories(node: colliderField, as: .sceneParticleCollider)
            circle.addChild(colliderField)
        }
        
        return circle
    }
    
    func cloner(node: SKNode, amount: Int, randomPosition: Bool, parent: SKNode) {
        for _ in 1...amount {
            let clonedNode = node.copy() as! SKSpriteNode
            clonedNode.name = "\(node.name ?? "")-\(UUID().uuidString)"
            clonedNode.color = getRandomColor()
            if randomPosition {
                clonedNode.position.x = CGFloat.random(in: -200...200)
                clonedNode.position.y = CGFloat.random(in: -400...400)
            }
            parent.addChild(clonedNode)
        }
    }
    
    func removeNodes(withName name: String) {
        let duration: CGFloat = 0.1
        let shrinkAndRemove = SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: -100, duration: duration),
                SKAction.scale(to: 0, duration: duration),
                SKAction.fadeOut(withDuration: duration)
            ]),
            SKAction.removeFromParent()
        ])
        
        self.enumerateChildNodes(withName: "//*\(name)*", using: {node, _ in
            node.run(shrinkAndRemove)
            //node.removeAllActions()
        })
    }
    
    func createPinnedObject(parent: SKNode) {
        let sprite = SKSpriteNode(color: .systemRed, size: CGSize(width: 60, height: 60))
        sprite.name = "flickable"
        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        sprite.constraints = [createSceneConstraints(node: sprite, insideRect: boundaryForSceneBodies)]
        sprite.physicsBody?.pinned = true
        sprite.physicsBody?.density = 1
        sprite.physicsBody?.categoryBitMask = BitMasks.sceneBody
        sprite.physicsBody?.collisionBitMask = BitMasks.sceneBody
        sprite.physicsBody?.fieldBitMask = BitMasks.sceneField
        sprite.position.y = 100
        parent.addChild(sprite)
    }
    
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
