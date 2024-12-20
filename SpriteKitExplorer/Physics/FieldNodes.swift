/**
 
 # Physical fields in SpriteKit
 
 - If a velocity field and a linear gravity field are both present in the scene, they are both disabled.
 - Fields that affects only bodies with a non zero velocity, such as turbulence, seem to always affect particles. Maybe particles have always a velocity.
 - I don't know how a velocity field with texture works.
 
 Achraf Kassioui
 Created: 24 April 2024
 Updated: 1 May 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - Live preview

struct FieldNodesView: View {
    @State private var sceneId = UUID()
    @State var isPaused: Bool = false
    var scene = FieldNodesScene()
    
    var body: some View {
        VStack(spacing: 0) {
            SpriteView(
                scene: scene,
                options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes]
                //debugOptions: [.showsPhysics]
            )
            /// force recreation using the unique ID
            .id(sceneId)
            .onAppear {
                /// generate a new ID on each appearance
                sceneId = UUID()
            }
            .ignoresSafeArea(.all, edges: [.top, .trailing, .leading])
            menuBar()
        }
        .background(.black)
    }
    
    private func menuBar() -> some View {
        HStack {
            Spacer()
            playPauseButton
            Spacer()
        }
        .padding([.top, .leading, .trailing], 10)
        //.frame(height: 60)
        .background(.ultraThinMaterial)
    }
    
    private var playPauseButton: some View {
        Button(action: {
            scene.isPaused.toggle()
            isPaused.toggle()
        }) {
            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 60, height: 60)
        .background(Color.black.opacity(0.5))
        .clipShape(Circle())
        .overlay(Circle().stroke(.black, lineWidth: 1))
    }
}

#Preview {
    FieldNodesView()
}

// MARK: - SpriteKit

class FieldNodesScene: SKScene {
    
    // MARK: didMove
    
    override func didMove(to view: SKView) {
        /// configure view
        size = view.bounds.size
        scaleMode = .resizeFill
        view.contentMode = .center
        backgroundColor = SKColor(red: 0.89, green: 0.89, blue: 0.84, alpha: 1)
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        view.isMultipleTouchEnabled = true
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -0)
        physicsWorld.speed = 1
        
        /// create background
        let gridTexture = generateGridTexture(cellSize: 15, rows: 70, cols: 70, linesColor: SKColor(white: 1, alpha: 0.1))
        let gridbackground = SKSpriteNode(texture: gridTexture)
        gridbackground.zPosition = -1
        //gridbackground.zRotation = .pi * 0.25
        addChild(gridbackground)
        
        /// create camera
        let inertialCamera = InertialCamera(scene: self)
        camera = inertialCamera
        addChild(inertialCamera)
        inertialCamera.zPosition = 99999
        inertialCamera.lockPan = true
        
        ///
        createPhysicalBoundaries(view)
        
        createParticles(view)
        createText(text: "🚀", rotation: -.pi*0.25, density: 1, colliderStrength: -1, withCollider: true)
        createLinearGravityField(size: CGSize(width: 200, height: 200), strength: 1, vector: vector_float3(-20, 0, 0))
        
        createVizButton(view)
    }
    
    // MARK: - Fields
    
    /// be careful with `print()` inside the block
    /// it can make Xcode crash
    func createCustomField(size: CGSize, strength: Float) {
        let field = SKFieldNode.customField { (position: vector_float3, velocity: vector_float3, mass: Float, charge: Float, deltaTime: TimeInterval) in
            return vector_float3(0, 0, 0)
        }
        field.name = "draggable"
        field.categoryBitMask = PhysicsCategory.field
        field.region = SKRegion(size: size)
        field.strength = strength
        field.isExclusive = true
        addChild(field)
        
        visualizeField(rectOfSize: size, text: "Custom Field", parent: field)
    }
    
    /// affects all physics bodies
    /// affects all particles
    func createElectricField(radius: Float, strength: Float) {
        let field = SKFieldNode.electricField()
        field.name = "draggable"
        field.categoryBitMask = PhysicsCategory.field
        field.region = SKRegion(radius: radius)
        field.strength = strength
        field.falloff = 0
        addChild(field)
        
        visualizeField(circleOfRadius: CGFloat(radius), text: "Electric Field", parent: field)
    }
    
    /// affects physics bodies that have a velocity
    /// affects all particles
    func createMagneticField(radius: Float, strength: Float) {
        let field = SKFieldNode.magneticField()
        field.name = "draggable"
        field.categoryBitMask = PhysicsCategory.field
        field.region = SKRegion(radius: radius)
        field.strength = strength
        addChild(field)
        
        visualizeField(circleOfRadius: CGFloat(radius), text: "Magnetic Field", parent: field)
    }
    
    /// applies a force in the opposite direction of the velocity
    /// affects physics bodies that have a velocity
    /// affects all particles
    /// positive strength decreases velocity, negative strength increases velocity
    func createDragField(size: CGSize, strength: Float) {
        let field = SKFieldNode.dragField()
        field.name = "draggable"
        field.categoryBitMask = PhysicsCategory.field
        field.region = SKRegion(size: size)
        field.strength = strength
        addChild(field)
        
        visualizeField(rectOfSize: size, text: "Drag Field", parent: field)
    }
    
    /// velocity field with velocity texture
    /// i don't know how to make this work
    func createVelocityMapField(size: CGSize, strength: Float, showTexture: Bool) {
        //let texture = SKTexture(vectorNoiseWithSmoothness: 1, size: size)
        let texture = SKTexture(noiseWithSmoothness: 1, size: size, grayscale: false)
        let field = SKFieldNode.velocityField(with: texture)
        field.name = "draggable"
        field.categoryBitMask = PhysicsCategory.field
        field.region = SKRegion(size: size)
        addChild(field)
        
        visualizeField(rectOfSize: size, text: "Velocity Map", parent: field)
        
        if showTexture {
            let velocityTexture = SKSpriteNode(texture: texture)
            velocityTexture.zPosition = 0
            field.addChild(velocityTexture)
        }
    }
    
    /// applies a constant velocity, overrides existing velocity
    /// works on physics bodies
    /// does not work on particles
    /// does not work if a linear gravity field is present
    func createVelocityField(size: CGSize, strength: Float, vector: vector_float3) {
        let field = SKFieldNode.velocityField(withVector: vector)
        field.name = "draggable"
        field.categoryBitMask = PhysicsCategory.field
        field.region = SKRegion(size: size)
        field.strength = strength
        field.isExclusive = true
        addChild(field)
        
        visualizeField(rectOfSize: size, text: "Velocity Field", parent: field)
    }
    
    /// applies a random acceleration proportional to the existing velocity
    /// a physics body with no velocity will not be affected
    /// affects all particles, even stationary ones. A bug, or does a particle always have a velocity?
    /// https://developer.apple.com/documentation/spritekit/skemitternode/1398006-fieldbitmask
    /// "The physics body is assumed to have a mass of 1.0 and a charge of 1.0".
    func createTurbulenceField(radius: Float, strength: Float, smoothness: CGFloat, speed: CGFloat) {
        let field = SKFieldNode.turbulenceField(withSmoothness: smoothness, animationSpeed: speed)
        field.name = "draggable"
        field.categoryBitMask = PhysicsCategory.field
        field.region = SKRegion(radius: radius)
        field.strength = strength
        addChild(field)
        
        visualizeField(circleOfRadius: CGFloat(radius), text: "Turbulence", parent: field)
    }
    
    /// applies a random accelerations
    /// affects physics bodies and particles
    func createNoiseField(radius: Float, strength: Float, smoothness: CGFloat, speed: CGFloat) {
        let field = SKFieldNode.noiseField(withSmoothness: smoothness, animationSpeed: speed)
        field.name = "draggable"
        field.categoryBitMask = PhysicsCategory.field
        field.region = SKRegion(radius: radius)
        field.strength = strength
        addChild(field)
        
        visualizeField(circleOfRadius: CGFloat(radius), text: "Random motion", parent: field)
    }
    
    /// applies a constant linear acceleration
    /// works on physics bodies and particles
    func createLinearGravityField(size: CGSize, strength: Float, vector: vector_float3) {
        let field = SKFieldNode.linearGravityField(withVector: vector)
        field.categoryBitMask = PhysicsCategory.field
        field.name = "draggable"
        field.region = SKRegion(size: size)
        field.strength = strength
        addChild(field)
        
        visualizeField(rectOfSize: size, text: "Accelerator", parent: field)
    }
    
    /// applies a centrpital acceleration
    /// works on physics bodies and particles
    func createRadialGravityField(radius: Float, strength: Float) {
        let field = SKFieldNode.radialGravityField()
        field.name = "draggable"
        field.categoryBitMask = PhysicsCategory.field
        field.region = SKRegion(radius: radius)
        field.strength = strength
        addChild(field)
        
        let text = strength < 0 ? "Repulsion" : "Attraction"
        visualizeField(circleOfRadius: CGFloat(radius), text: text, parent: field)
    }
    
    /// affects all physics bodies and particles
    /// acts like a loose containement field
    func createSpringField(size: CGSize, strength: Float) {
        let field = SKFieldNode.springField()
        field.name = "draggable"
        field.categoryBitMask = PhysicsCategory.field
        field.region = SKRegion(size: size)
        field.strength = strength
        addChild(field)
        
        visualizeField(rectOfSize: size, text: "Spring Field", parent: field)
    }
    
    /// works on physics bodies and particles
    func createVortexField(radius: Float, strength: Float) {
        let field = SKFieldNode.vortexField()
        field.name = "draggable"
        field.categoryBitMask = PhysicsCategory.field
        field.region = SKRegion(radius: radius)
        field.strength = strength
        addChild(field)
        
        visualizeField(circleOfRadius: CGFloat(radius), text: "Vortex", parent: field)
    }
    
    // MARK: - Objects
    
    var physicalFrame = SKShapeNode()
    
    func createConstraints(node: SKNode) -> SKConstraint {
        let xRange = SKRange(lowerLimit: physicalFrame.frame.minX + node.frame.size.width / 2,
                             upperLimit: physicalFrame.frame.maxX - node.frame.size.width / 2)
        let yRange = SKRange(lowerLimit: physicalFrame.frame.minY + node.frame.size.height / 2,
                             upperLimit: physicalFrame.frame.maxY - node.frame.size.height / 2)
        
        let constraint = SKConstraint.positionX(xRange, y: yRange)
        return constraint
    }
    
    struct PhysicsCategory {
        static let body: UInt32 = 0x1 << 0
        static let particles: UInt32 = 0x1 << 1
        static let field: UInt32 = 0x1 << 2
        static let particleCollider: UInt32 = 0x1 << 3
    }
    
    func createText(text: String, rotation: CGFloat, density: CGFloat, colliderStrength: Float, withCollider: Bool) {
        let text = SKLabelNode(text: text)
        text.name = "draggable"
        text.fontName = "Futura-Medium"
        text.fontSize = 80
        text.fontColor = SKColor(white: 1, alpha: 0.7)
        text.verticalAlignmentMode = .center
        text.horizontalAlignmentMode = .center
        let textFrame = text.calculateAccumulatedFrame().size
        text.physicsBody = SKPhysicsBody(rectangleOf: textFrame)
        text.physicsBody?.categoryBitMask = PhysicsCategory.body
        text.physicsBody?.fieldBitMask = PhysicsCategory.field
        text.physicsBody?.density = density
        text.zRotation = rotation
        text.constraints = [createConstraints(node: text)]
        addChild(text)
        
        if withCollider {
            let field = SKFieldNode.radialGravityField()
            field.categoryBitMask = PhysicsCategory.particleCollider
            field.strength = colliderStrength
            field.region = SKRegion(size: textFrame)
            text.addChild(field)
            
            visualizeField(rectOfSize: text.calculateAccumulatedFrame().size, text: "", parent: field)
        }
    }
    
    func createEdgeLoop() {
        let radius: CGFloat = 150
        let loop = SKShapeNode(circleOfRadius: radius)
        loop.lineWidth = 10
        loop.strokeColor = .black
        let loopPath = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        loop.physicsBody = SKPhysicsBody(edgeLoopFrom: loopPath)
        addChild(loop)
    }
    
    func createSpriteWithCollider(count: Int, withCollider: Bool) {
        for _ in 1...count {
            let sprite = SKSpriteNode(imageNamed: "rectangle-60-12-fill")
            sprite.colorBlendFactor = 1
            sprite.color = .systemRed
            sprite.name = "draggable"
            sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
            sprite.physicsBody?.categoryBitMask = PhysicsCategory.body
            sprite.physicsBody?.fieldBitMask = PhysicsCategory.field
            sprite.physicsBody?.charge = 1
            sprite.constraints = [createConstraints(node: sprite)]
            sprite.position.y = -280
            addChild(sprite)
            
            if withCollider {
                let colliderSize = CGSize(width: 60, height: 60)
                let colliderField = SKFieldNode.radialGravityField()
                colliderField.strength = -1
                colliderField.region = SKRegion(size: colliderSize)
                colliderField.categoryBitMask = PhysicsCategory.particleCollider
                sprite.addChild(colliderField)
                
                visualizeField(rectOfSize: colliderSize, text: "Collider", parent: colliderField)
            }
        }
    }
    
    func createParticles(_ view: SKView) {
        if let particleEmitter = SKEmitterNode(fileNamed: "Water") {
            //particleEmitter.name = "draggable"
            particleEmitter.fieldBitMask = PhysicsCategory.field | PhysicsCategory.particleCollider
            //particleEmitter.position.y = -view.bounds.height/2 + particleEmitter.frame.height
            //particleEmitter.position.x = -view.bounds.width/2
            //particleEmitter.particlePositionRange = CGVector(dx: 0, dy: 150)
            
            let referenceNode = SKNode()
            addChild(referenceNode)
            //particleEmitter.targetNode = referenceNode
            
            let sprite = SKSpriteNode(color: .clear, size: CGSize(width: 60, height: 60))
            sprite.name = "draggable"
            //sprite.run(SKAction.repeatForever(SKAction.rotate(byAngle: 2 * .pi, duration: 4)))
            sprite.addChild(particleEmitter)
            addChild(sprite)
            
            let constraint = SKConstraint.orient(to: referenceNode, offset: SKRange(constantValue: 0.0))
            particleEmitter.constraints = [constraint]
            
            /*
            let rotationRange = SKRange(lowerLimit: 0, upperLimit: .pi * 2) // Full circle in radians
            let rotateAction = SKAction.customAction(withDuration: 1.0) { node, elapsedTime in
                let fraction = elapsedTime / 1.0
                let angle = rotationRange.lowerLimit + fraction * (rotationRange.upperLimit - rotationRange.lowerLimit)
                (node as? SKEmitterNode)?.emissionAngle = angle
            }
            let repeatAction = SKAction.repeatForever(rotateAction)
            sprite.run(repeatAction)
             */
        }
    }
    
    func createManyTriangles() {
        for _ in 1...100 {
            let triangleTexture = SKTexture(imageNamed: "block_triangle")
            let triangleSize = CGSize(width: 36, height: 18)
            let physicalSize = CGSize(width: 34, height: 17)
            let triangle = SKSpriteNode(texture: triangleTexture, size: triangleSize)
            triangle.name = "draggable"
            triangle.colorBlendFactor = 1
            triangle.color = .systemYellow
            triangle.physicsBody = SKPhysicsBody(texture: triangleTexture, size: physicalSize)
            triangle.physicsBody?.categoryBitMask = PhysicsCategory.body
            triangle.physicsBody?.fieldBitMask = PhysicsCategory.field
            triangle.constraints = [createConstraints(node: triangle)]
            triangle.position.x = CGFloat.random(in: -200...200)
            triangle.position.y = CGFloat.random(in: -400...400)
            addChild(triangle)
        }
    }
    
    func createManyLabels(text: String, color: SKColor, count: Int) {
        for _ in 1...count {
            let label = SKLabelNode(text: text)
            label.name = "draggable"
            label.fontColor = color
            label.fontName = "Menlo-Bold"
            label.verticalAlignmentMode = .center
            label.physicsBody = SKPhysicsBody(rectangleOf: label.frame.size)
            label.physicsBody?.density = 10
            label.physicsBody?.charge = -1
            label.physicsBody?.categoryBitMask = PhysicsCategory.body
            label.physicsBody?.fieldBitMask = PhysicsCategory.field
            label.constraints = [createConstraints(node: label)]
            addChild(label)
        }
    }
    
    func createManyBalls(amount: Int, radius: CGFloat, color: SKColor, particleCollider: Bool) {
        for _ in 1...amount {
            let circle = SKSpriteNode(imageNamed: "circle-30-fill")
            circle.name = "draggable"
            circle.size = CGSize(width: radius*2, height: radius*2)
            circle.position.x = CGFloat.random(in: -200...200)
            circle.position.y = CGFloat.random(in: -400...400)
            circle.colorBlendFactor = 1
            circle.color = color
            circle.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            circle.physicsBody?.charge = 1
            circle.physicsBody?.density = 1
            circle.physicsBody?.categoryBitMask = PhysicsCategory.body
            circle.physicsBody?.fieldBitMask = PhysicsCategory.field
            circle.constraints = [createConstraints(node: circle)]
            addChild(circle)
            
            /// this will make every ball collide with particles
            /// costly if there are too many balls
            if particleCollider {
                let colliderField = SKFieldNode.radialGravityField()
                colliderField.strength = -1
                colliderField.region = SKRegion(radius: Float(radius))
                colliderField.categoryBitMask = PhysicsCategory.particleCollider
                circle.addChild(colliderField)
            }
        }
    }
    
    func createPhysicalBoundaries(_ view: SKView) {
        let physicsBoundaries = CGRect(
            x: -view.frame.width / 2,
            y: -view.frame.height / 2,
            width: view.frame.width,
            height: view.frame.height
        )
        
        physicalFrame = SKShapeNode(rect: physicsBoundaries)
        physicalFrame.lineWidth = 3
        physicalFrame.strokeColor = SKColor(white: 0, alpha: 0.9)
        physicalFrame.physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBoundaries)
        physicalFrame.isUserInteractionEnabled = false
        physicalFrame.zPosition = -1
        physicalFrame.physicsBody?.isDynamic = false
        physicalFrame.physicsBody?.categoryBitMask = PhysicsCategory.body
        physicalFrame.physicsBody?.fieldBitMask = PhysicsCategory.field
        addChild(physicalFrame)
    }
    
    // MARK: - UI
    
    let vizStrokeCcolor = SKColor(red: 0.49, green: 0.74, blue: 0.74, alpha: 0.7)
    let vizFillColor = SKColor(red: 0.49, green: 0.74, blue: 0.74, alpha: 0.2)
    let vizFontName = "Menlo-Bold"
    let vizFontSize: CGFloat = 16
    let margin: CGFloat = 20
    
    func createVizButton(_ view: SKView) {
        let button = ButtonPhysical(
            view: view,
            shape: .round,
            size: CGSize(width: 60, height: 60),
            iconInactive: SKTexture(imageNamed: "eye-slash"),
            iconActive: SKTexture(imageNamed: "eye"),
            iconSize: CGSize(width: 32, height: 32),
            theme: .dark,
            isPhysical: false,
            onTouch: {
                self.enumerateChildNodes(withName: "//viz", using: { node, _ in
                    node.isHidden.toggle()
                })
            }
        )
        button.zPosition = 1000
        button.position.x = -view.bounds.width/2 + button.frame.width/2 + view.safeAreaInsets.right + margin
        button.position.y = -view.bounds.height/2 + button.frame.height/2 + view.safeAreaInsets.bottom + margin
        camera?.addChild(button)
    }
    
    func createIndicationArrow(angle: CGFloat) {
        let arrow = SKSpriteNode(imageNamed: "arrowshape.right.fill")
        arrow.name = "draggable"
        arrow.colorBlendFactor = 1
        arrow.color = .white
        arrow.setScale(0.5)
        arrow.zRotation = angle
        addChild(arrow)
        
        let flash = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0),
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.4)
        ])
        
        arrow.userData = ["animation": flash]
    }
    
    // MARK: - Update loop
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.update()
        }
    }
    
    // MARK: - didSimulate
    
    override func didSimulatePhysics() {
        enumerateChildNodes(withName: "//.", using: { node, _ in
            if let velocity = node.physicsBody?.velocity {
                /// we set a max speed of 300 m/s, which is 45000 points/s in SpriteKit
                /// we use the squared value to avoid a square root calculation later on
                let maxSpeedSquared: CGFloat = 2025000000
                if velocity.dx.isNaN || velocity.dy.isNaN {
                    /// handle node with NaN velocity, typically thrown off by a vortex field
                    print("Velocity components are NaN for node \(node)")
                    node.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                    node.position = .zero
                } else {
                    let speedSquared = velocity.dx * velocity.dx + velocity.dy * velocity.dy
                    if speedSquared > maxSpeedSquared {
                        print("Velocity exceeds 300m/s for node \(node.name ?? "")")
                        node.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                        node.position = .zero
                    }
                }
            }
        })
    }
    
    // MARK: - Touch events
    
    private var draggingNodes: [UITouch: SKNode] = [:]
    private var touchOffsets: [UITouch: CGPoint] = [:]
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            /// dragging logic
            let location = touch.location(in: self)
            let touchedNodes = nodes(at: location)
            
            if let selectedNode = touchedNodes.first(where: { $0.name?.contains("draggable") ?? false }) {
                touchOffsets[touch] = location - selectedNode.position
                selectedNode.physicsBody?.isDynamic = false
                draggingNodes[touch] = selectedNode
            }
            /// end dragging logic
            
            if let inertialCamera = camera as? InertialCamera {
                inertialCamera.stopInertia()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            /// dragging logic
            if let selectedNode = draggingNodes[touch], let offset = touchOffsets[touch] {
                let newPosition = touch.location(in: self) - offset
                selectedNode.position = newPosition
            }
            /// end dragging logic
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            /// dragging logic
            if let node = draggingNodes.removeValue(forKey: touch) {
                node.physicsBody?.isDynamic = true
            }
            
            draggingNodes[touch] = nil
            touchOffsets[touch] = nil
            /// end dragging logic
            
            /// arrow indication logic
            let location = touch.location(in: self)
            let touchedNode = atPoint(location)
            if touchedNode.name == "draggable", let flashAction = touchedNode.userData?["animation"] as? SKAction {
                touchedNode.run(SKAction.repeat(flashAction, count: 3))
            }
            /// end arrow indication logic
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
