/**
 
 # SpriteKit Scene Extensions
 
 Achraf Kassioui
 Created: 3 May 2024
 Updated: 3 May 2024
 
 */

import SpriteKit

extension SKScene {
    
    // MARK: - Helpers
    /**
     
     Cancel all scales applied to the parent of this node.
     Call the function after the node has been added to its parent.
     ```
     parentNode.addChild(myNode)
     myNode.setScale(removeCumulativeScale(from: myNode))
     
     ```
     
     Created: 23 May 2024
     Updated: 24 May 2024
     
     */
    enum CumulativeScale {
        case x
        case y
        case xy
    }
    
    func getScaleRelativeToScene(node: SKNode, axis: CumulativeScale) -> CGFloat {
        var cumulativeScaleX: CGFloat = 1.0
        var cumulativeScaleY: CGFloat = 1.0
        
        var currentNode: SKNode? = node.parent
        while let node = currentNode {
            cumulativeScaleX *= node.xScale
            cumulativeScaleY *= node.yScale
            currentNode = node.parent
        }
        
        let cumulativeScaleXY = (cumulativeScaleX + cumulativeScaleY) / 2.0
        
        let value: CGFloat
        
        switch axis {
        case .x:
            value = cumulativeScaleX
        case .y:
            value = cumulativeScaleY
        case .xy:
            value = cumulativeScaleXY
        }
        
        return value
    }
    
    func removeCumulativeScale(from node: SKNode) -> CGFloat {
        var cumulativeScaleX: CGFloat = 1.0
        var cumulativeScaleY: CGFloat = 1.0
        
        var currentNode: SKNode? = node.parent
        while let node = currentNode {
            cumulativeScaleX *= node.xScale
            cumulativeScaleY *= node.yScale
            currentNode = node.parent
        }
        
        let cumulativeScale = (cumulativeScaleX + cumulativeScaleY) / 2.0
        return 1.0 / cumulativeScale
    }
    
    // MARK: - 9 parts slicing
    
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
    
    // MARK: - Constraints
    
    /**
     
     Created: 23 May 2024
     Updated: 24 May 2024
     
     */
    
    enum UIRegion {
        case view, leftEdge, rightEdge
    }
    
    func createConstraintsWithRectangle(node: SKNode, rectangle: SKNode) -> SKConstraint {
        let xRange = SKRange(lowerLimit: rectangle.frame.minX + node.frame.size.width / 2,
                             upperLimit: rectangle.frame.maxX - node.frame.size.width / 2)
        let yRange = SKRange(lowerLimit: rectangle.frame.minY + node.frame.size.height / 2,
                             upperLimit: rectangle.frame.maxY - node.frame.size.height / 2)
        
        let constraint = SKConstraint.positionX(xRange, y: yRange)
        constraint.referenceNode = rectangle
        return constraint
    }
    
    func createConstraintsInView(view: SKView, node: SKNode, region: UIRegion, margin: CGFloat? = 0, vizParent: SKNode? = nil) -> SKConstraint {
        let margin = margin ?? 0
        
        let maxY = view.bounds.height/2 - view.safeAreaInsets.top - node.frame.height/2 - margin
        let minY = -view.bounds.height/2 + view.safeAreaInsets.bottom + node.frame.height/2 + margin
        
        let minX = -view.bounds.width/2 + node.frame.width/2 + margin
        let maxX = view.bounds.width/2 - node.frame.width/2 - margin
        
        let constraint: SKConstraint
        
        let path: CGMutablePath
        let shape = SKShapeNode()
        shape.strokeColor = .systemRed
        shape.lineWidth = 2
        shape.fillColor = SKColor.red.withAlphaComponent(0.1)
        shape.zPosition = 9999
        shape.isUserInteractionEnabled = false
        
        /// visualize the center
        if vizParent != nil {
            let plusSign = CGMutablePath()
            plusSign.move(to: CGPoint(x: 0, y: 22))
            plusSign.addLine(to: CGPoint(x: 0, y: -22))
            plusSign.move(to: CGPoint(x: -22, y: 0))
            plusSign.addLine(to: CGPoint(x: 22, y: 0))
            let nodeCenter = SKShapeNode(path: plusSign)
            nodeCenter.strokeColor = .systemRed
            nodeCenter.lineWidth = 2
            nodeCenter.fillColor = SKColor.red.withAlphaComponent(0.1)
            nodeCenter.zPosition = 9999
            nodeCenter.isUserInteractionEnabled = false
            node.addChild(nodeCenter)
            nodeCenter.setScale(removeCumulativeScale(from: nodeCenter))
        }
        
        switch region {
        case .view:
            let horizontalRange = SKRange(lowerLimit: minX, upperLimit: maxX)
            let verticalRange = SKRange(lowerLimit: minY, upperLimit: maxY)
            constraint = SKConstraint.positionX(horizontalRange, y: verticalRange)
            
            if let parent = vizParent {
                path = CGMutablePath()
                path.move(to: CGPoint(x: minX, y: maxY))
                path.addLine(to: CGPoint(x: maxX, y: maxY))
                path.addLine(to: CGPoint(x: maxX, y: minY))
                path.addLine(to: CGPoint(x: minX, y: minY))
                path.closeSubpath()
                shape.path = path
                parent.addChild(shape)
            }
            
        case .leftEdge:
            let horizontalRange = SKRange(constantValue: minX)
            let verticalRange = SKRange(lowerLimit: minY, upperLimit: maxY)
            constraint = SKConstraint.positionX(horizontalRange, y: verticalRange)
            
            if let parent = vizParent {
                path = CGMutablePath()
                path.move(to: CGPoint(x: minX, y: maxY))
                path.addLine(to: CGPoint(x: minX, y: minY))
                path.closeSubpath()
                shape.path = path
                parent.addChild(shape)
            }
            
        case .rightEdge:
            let horizontalRange = SKRange(constantValue: maxX)
            let verticalRange = SKRange(lowerLimit: minY, upperLimit: maxY)
            constraint = SKConstraint.positionX(horizontalRange, y: verticalRange)
            
            if let parent = vizParent {
                path = CGMutablePath()
                path.move(to: CGPoint(x: maxX, y: maxY))
                path.addLine(to: CGPoint(x: maxX, y: minY))
                path.closeSubpath()
                shape.path = path
                parent.addChild(shape)
            }
        }
        
        return constraint
    }
    
    // MARK: - Labels
    /**
     
     Created: 23 May 2024
     
     */
    
    func createSpriteLabel(view: SKView, text: String, color: SKColor, size: CGFloat) -> SKSpriteNode {
        let label = SKLabelNode(text: text)
        label.fontColor = color
        label.fontName = "SF-Pro"
        label.fontSize = size
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        
        let sprite = SKSpriteNode(texture: view.texture(from: label))
        return sprite
    }
    
    // MARK: - Layout
    /**
     
     Created: 21 May 2024
     
     */
    enum NodeDistribution {
        case vertical
        case horizontal
    }
    
    func distributeNodes(direction: NodeDistribution, container: SKNode, nodes: [SKNode], spacing: CGFloat? = 0, padding: CGFloat? = 0) {
        guard !nodes.isEmpty else {
            print("distributeNodes: no nodes to distribute")
            return
        }
        
        let spacing: CGFloat = spacing ?? 0
        let padding: CGFloat = padding ?? 0
        var totalSize: CGFloat = 0
        let totalSpacing: CGFloat = CGFloat(nodes.count - 1) * spacing
        
        for node in nodes {
            switch direction {
            case .vertical:
                totalSize += node.calculateAccumulatedFrame().height
            case .horizontal:
                totalSize += node.calculateAccumulatedFrame().width
            }
        }
        
        let totalSizeWithSpacing = totalSize + totalSpacing + 2 * padding
        
        switch direction {
        case .vertical:
            var yPosition = totalSizeWithSpacing / 2 - padding
            for node in nodes {
                node.position.y = yPosition - node.calculateAccumulatedFrame().height / 2
                yPosition -= node.calculateAccumulatedFrame().height + spacing
                container.addChild(node)
            }
            
        case .horizontal:
            var xPosition = -totalSizeWithSpacing / 2 + padding
            for node in nodes {
                node.position.x = xPosition + node.calculateAccumulatedFrame().width / 2
                xPosition += node.calculateAccumulatedFrame().width + spacing
                container.addChild(node)
            }
        }
    }
    
    // MARK: - View Debug
    /**
     
     Created: 19 May 2024
     
     */
    func toggleDebugOptions(view: SKView) {
        view.showsFPS.toggle()
        view.showsPhysics.toggle()
        view.showsNodeCount.toggle()
        view.showsDrawCount.toggle()
        view.showsFields.toggle()
        view.showsQuadCount.toggle()
    }
    
    // MARK: - Physics Categories
    /**
     
     Pre-made bitmasks for common use.
     
     Created: 10 May 2024
     Updated: 27 May 2024
     
     */
    struct BitMasks {
        static let sceneBody: UInt32 = 0x1 << 0
        static let sceneField: UInt32 = 0x1 << 1
        static let sceneParticle: UInt32 = 0x1 << 2
        static let sceneParticleCollider: UInt32 = 0x1 << 3
        
        static let sceneBoundary: UInt32 = 0x1 << 4
        
        static let uiBody: UInt32 = 0x1 << 5
        static let uiBodyLeft: UInt32 = 0x1 << 6
        static let uiBodyRight: UInt32 = 0x1 << 7
        
        static let uiField: UInt32 = 0x1 << 8
        static let uiFieldLeft: UInt32 = 0x1 << 9
        static let uiFieldRight: UInt32 = 0x1 << 10
        
        static let uiBoundary: UInt32 = 0x1 << 11
    }
    
    enum PhysicsCategory {
        case sceneBody
        case sceneField
        case sceneParticle
        case sceneParticleCollider
        case sceneBoundary
        
        case UIBody
        case UIBodyLeft
        case UIBodyRight
        case UIParticle
        
        case UIField
        case UIFieldLeft
        case UIFieldRight
        
        case UIBoundary
        
        case ethereal
    }
    
    func setupPhysicsCategories(node: SKNode, as category: PhysicsCategory) {
        switch category {
        case .UIBody:
            node.physicsBody?.categoryBitMask = BitMasks.uiBody
            node.physicsBody?.collisionBitMask = BitMasks.uiBoundary | BitMasks.uiBody
            node.physicsBody?.fieldBitMask = BitMasks.uiField
            node.physicsBody?.affectedByGravity = false
            node.physicsBody?.allowsRotation = false
            node.physicsBody?.linearDamping = 4
            node.physicsBody?.charge = 1
        case .UIBodyLeft:
            node.physicsBody?.categoryBitMask = BitMasks.uiBodyLeft
            node.physicsBody?.collisionBitMask = BitMasks.uiBoundary | BitMasks.uiBody | BitMasks.uiBodyRight | BitMasks.uiBodyLeft
            node.physicsBody?.fieldBitMask = BitMasks.uiFieldLeft
            node.physicsBody?.affectedByGravity = false
            node.physicsBody?.allowsRotation = false
            node.physicsBody?.linearDamping = 4
            node.physicsBody?.charge = 1
        case .UIBodyRight:
            node.physicsBody?.categoryBitMask = BitMasks.uiBodyRight
            node.physicsBody?.collisionBitMask = BitMasks.uiBoundary | BitMasks.uiBody | BitMasks.uiBodyLeft
            node.physicsBody?.fieldBitMask = BitMasks.uiFieldRight
            node.physicsBody?.affectedByGravity = false
            node.physicsBody?.allowsRotation = false
            node.physicsBody?.linearDamping = 4
            node.physicsBody?.charge = 1
        case .UIParticle:
            if let particleEmitter = node as? SKEmitterNode {
                particleEmitter.fieldBitMask = BitMasks.uiField | BitMasks.uiFieldLeft | BitMasks.uiFieldRight
            }
        case .UIField:
            if let field = node as? SKFieldNode {
                field.categoryBitMask = BitMasks.uiField
            }
        case .UIFieldLeft:
            if let field = node as? SKFieldNode {
                field.categoryBitMask = BitMasks.uiFieldLeft
            }
        case .UIFieldRight:
            if let field = node as? SKFieldNode {
                field.categoryBitMask = BitMasks.uiFieldRight
            }
            
        case .UIBoundary:
            node.physicsBody?.categoryBitMask = BitMasks.uiBoundary
            node.physicsBody?.collisionBitMask = BitMasks.uiBody | BitMasks.uiBodyLeft | BitMasks.uiBodyRight
            node.physicsBody?.fieldBitMask = 0
            
        case .sceneBody:
            node.physicsBody?.categoryBitMask = BitMasks.sceneBody
            node.physicsBody?.collisionBitMask = BitMasks.sceneBody | BitMasks.sceneBoundary
            node.physicsBody?.fieldBitMask = BitMasks.sceneField
            node.physicsBody?.charge = 1
            node.physicsBody?.density = 1
        case .sceneField:
            if let field = node as? SKFieldNode {
                field.categoryBitMask = BitMasks.sceneField
            }
        case .sceneParticle:
            if let particleEmitter = node as? SKEmitterNode {
                particleEmitter.fieldBitMask = BitMasks.sceneField | BitMasks.sceneParticleCollider
            }
        case .sceneParticleCollider:
            if let field = node as? SKFieldNode {
                field.categoryBitMask = BitMasks.sceneParticleCollider
            }
        case .sceneBoundary:
            node.physicsBody?.categoryBitMask = BitMasks.sceneBoundary
            node.physicsBody?.collisionBitMask = BitMasks.sceneBody
            node.physicsBody?.fieldBitMask = 0
            node.physicsBody?.isDynamic = false
            node.physicsBody?.restitution = 0.2
        case .ethereal:
            node.physicsBody?.isDynamic = false
            node.physicsBody?.categoryBitMask = 0
            node.physicsBody?.collisionBitMask = 0
            node.physicsBody?.contactTestBitMask = 0
            node.physicsBody?.fieldBitMask = 0
        }
    }
    
    // MARK: - Visualize Node Frame
    /**
     
     Create a shape with the same position and size as the accumulated frame of a node.
     The accumulated frame is the rectangular straight shape that includes the node and its children.
     
     Created: 10 May 2024
     Updated: 10 May 2024
     
     */
    func visualizeFrame(node: SKNode) -> SKNode {
        let frame = SKShapeNode(rect: node.calculateAccumulatedFrame())
        frame.path = frame.path?.copy(dashingWithPhase: 0, lengths: [8, 8])
        frame.lineWidth = 2
        frame.strokeColor = SKColor(white: 1, alpha: 1)
        
        if let parent = node.parent {
            //let positionInScene = convert(node.position, from: parent)
            //frame.position = positionInScene
            
            if let camera = parent as? SKCameraNode {
                frame.yScale = camera.yScale
                frame.xScale = camera.xScale
                frame.zRotation = camera.zRotation
            }
        }
        
        return frame
    }
    
    /**
     
     Another version.
     Explain and improve
     
     Created: 13 March 2024
     Updated: 15 May 2024
     
     */
    func visualizeFrameOnce(nodeName: String, in scene: SKScene) {
        guard let targetNode = scene.childNode(withName: "//\(nodeName)") else { return }
        
        let visualizationNodeName = "visualizationFrameNode"
        let existingVisualizationNode = scene.childNode(withName: visualizationNodeName) as? SKShapeNode
        
        let frame: CGRect = targetNode.calculateAccumulatedFrame()
        let path = CGPath(rect: frame, transform: nil)
        
        if let visualizationNode = existingVisualizationNode {
            visualizationNode.path = path
        } else {
            let frameNode = SKShapeNode(path: path)
            frameNode.name = visualizationNodeName
            frameNode.lineWidth = 2
            frameNode.strokeColor = SKColor.white
            frameNode.zPosition = 100
            scene.addChild(frameNode)
        }
    }
    
    // MARK: - Cap Physics Bodies Velocity
    
    func clampVelocity() {
        /// we set a max speed, and we use its squared value to avoid a square root calculation
        /// In SpriteKit, 1 meter = 150 points
        /// 100km/h = 17640000
        /// 300m/s   = 2025000000
        let maxSpeedSquared: CGFloat = 2025000000
        
        enumerateChildNodes(withName: "//.", using: { node, _ in
            if let velocity = node.physicsBody?.velocity {
                if velocity.dx.isNaN || velocity.dy.isNaN {
                    /// handle node with NaN velocity, for example nodes thrown away by a vortex field
                    print("Velocity components are NaN for node \(node)")
                    node.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                    node.position = .zero
                } else {
                    let speedSquared = velocity.dx * velocity.dx + velocity.dy * velocity.dy
                    if speedSquared > maxSpeedSquared {
                        print("Max velocity exceeded for node \(node.name ?? "")")
                        node.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                        node.position = .zero
                    }
                }
            }
        })
    }
    
    // MARK: - Clean Physics
    /**
     
     SpriteKit physics world puts a small circular physics body at the origin of the scene. That body messes up with other physics bodies such as physics joints.
     This function enumerates all physics bodies in the scene, and disable their collision with other bodies.
     Call this function before any physics setup.
     
     https://stackoverflow.com/questions/41446160/unexpected-physicsbody-in-spritekit-scene
     
     Created: May 2024
     Updated: 10 May 2024
     
     */
    func cleanPhysics() {
        self.physicsWorld.enumerateBodies(in:(self.frame)) { body, stop in
            body.collisionBitMask = 0
        }
    }
    
    // MARK: - Visualize Physics Fields
    /**
     
     Create visualization objects for SKFieldNode
     
     Created: April 2024
     
     */    
    struct fieldVisualizationStyle {
        static let strokeColor = SKColor(red: 0.49, green: 0.74, blue: 0.74, alpha: 0.7)
        static let fillColor = SKColor(red: 0.49, green: 0.74, blue: 0.74, alpha: 0.2)
        static let fontName = "Menlo-Bold"
        static let fontSize: CGFloat = 16
    }
    
    fileprivate func visualizeFieldLabel(text: String, parent: SKNode) {
        let label = SKLabelNode(text: text)
        label.fontName = fieldVisualizationStyle.fontName
        label.fontSize = fieldVisualizationStyle.fontSize
        label.fontColor = fieldVisualizationStyle.strokeColor
        label.verticalAlignmentMode = .bottom
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: parent.frame.maxY + 20)
        parent.addChild(label)
    }
    
    func visualizeField(circleOfRadius radius: CGFloat, text: String, parent: SKNode) {
        let viz = SKShapeNode(circleOfRadius: radius)
        viz.name = "viz"
        viz.lineWidth = 1
        viz.strokeColor = fieldVisualizationStyle.strokeColor
        viz.fillColor = fieldVisualizationStyle.fillColor
        viz.zPosition = 0
        parent.addChild(viz)
        
        visualizeFieldLabel(text: text, parent: viz)
    }
    
    func visualizeField(rectOfSize size: CGSize, text: String, parent: SKNode) {
        let viz = SKShapeNode(rectOf: size)
        viz.name = "viz"
        viz.lineWidth = 1
        viz.strokeColor = fieldVisualizationStyle.strokeColor
        viz.fillColor = fieldVisualizationStyle.fillColor
        viz.zPosition = 0
        parent.addChild(viz)
        
        visualizeFieldLabel(text: text, parent: viz)
    }
    
}
