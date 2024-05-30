/**
 
 # Physics Joints and Camera
 
 A scene to investigate how physics joints work across various camera scales.
 
 Achraf Kassioui
 Created: 28 May 2024
 Updated: 30 May 2024
 
 */

import SwiftUI
import SpriteKit

struct JointsWithCameraView: View {
    var scene = JointsWithCameraScene()
    @State var showPhysics = false
    
    var body: some View {
        VStack(spacing: 0) {
            SpriteView(
                scene: scene,
                options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes]
            )
            .ignoresSafeArea()
            
            VStack {
                menuBar()
            }
        }
        .background(.black)
    }
    
    private func menuBar() -> some View {
        HStack (spacing: 2) {
            Spacer()
            
            /// Zoom Button 1
            Button(action: {
                scene.setCameraScale(2)
            }, label: {
                Text("50%")
            })
            .buttonStyle(.borderedProminent)
            
            /// Zoom Button 2
            Button(action: {
                scene.setCameraScale(1)
            }, label: {
                Text("100%")
            })
            .buttonStyle(.borderedProminent)
            
            /// Zoom Button 3
            Button(action: {
                scene.setCameraScale(0.5)
            }, label: {
                Text("200%")
            })
            .buttonStyle(.borderedProminent)
            
            Spacer()
            
            /// Debug Button
            Button(action: {
                showPhysics.toggle()
                scene.toggleDebugView(showPhysics)
            }, label: {
                Text(showPhysics ? "Hide Physics" : "Show Physics")
            })
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding([.top, .leading, .trailing], 10)
    }
}

#Preview {
    JointsWithCameraView()
}

class JointsWithCameraScene: SKScene {
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        baseSceneSize = size
        backgroundColor = .darkGray
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        
        cleanPhysics()
        
        createInertialCamera(scene: self)
        createSceneLayers()
        createZoomLabel(view: view, parent: uiLayer)
        
        createPhysicalBoundaryForUIBodies(view: view, parent: uiLayer)
        createUIPhysicsJoint(parent: uiLayer)
        //createSpringJointAndWheels(parent: uiLayer)
        
        createSceneObjects(parent: objectsLayer)
    }
    
    // MARK: - Variables
    
    var baseSceneSize: CGSize = .zero
    let uiLayer = SKNode()
    let objectsLayer = SKNode()
    let zoomLabel = SKLabelNode()
    
    // MARK: - Scene Setup
    
    func createSceneLayers() {
        guard let camera = self.camera else {
            print("No camera in scene")
            return
        }
        
        uiLayer.zPosition = 9999
        camera.addChild(uiLayer)
        
        objectsLayer.zPosition = 1
        self.addChild(objectsLayer)
    }
    
    func toggleDebugView(_ show: Bool) {
        guard let view = self.view else { return }
        view.showsFPS = show
        view.showsPhysics = show
        view.showsNodeCount = show
        view.showsDrawCount = show
        view.showsFields = show
        view.showsQuadCount = show
    }
    
    // MARK: - Camera
    
    func createZoomLabel(view: SKView, parent: SKNode) {
        zoomLabel.fontName = "Menlo-Bold"
        zoomLabel.fontSize = 16
        zoomLabel.fontColor = .white
        zoomLabel.horizontalAlignmentMode = .center
        zoomLabel.verticalAlignmentMode = .center
        zoomLabel.position.y = view.bounds.height/2 - zoomLabel.calculateAccumulatedFrame().height/2 - view.safeAreaInsets.top - 20
        parent.addChild(zoomLabel)
    }
    
    func updateZoomLabel() {
        if let camera = self.camera {
            let zoomPercentage = 100 / (camera.xScale)
            zoomLabel.text = String(format: "Zoom: %.0f%%", zoomPercentage)
        }
    }
    
    func setSceneSize(_ factor: CGFloat) {
        let newSceneWidth = baseSceneSize.width * factor
        let newSceneHeight = baseSceneSize.height * factor
        
        self.size = CGSize(width: newSceneWidth, height: newSceneHeight)
    }
    
    func setCameraScale(_ scale: CGFloat) {
        if let camera = self.camera {
            let beforeScale = SKAction.run {
                
            }
            
            let ScaleAction = SKAction.scale(to: scale, duration: 0.2)
            ScaleAction.timingMode = .easeInEaseOut
            
            let afterScale = SKAction.run {

            }
            
            let sequence = SKAction.sequence([beforeScale, ScaleAction, afterScale])
            camera.run(sequence)
        }
    }

    func createInertialCamera(scene: SKScene) {
        let inertialCamera = InertialCamera(scene: scene)
        inertialCamera.lockRotation = true
        inertialCamera.minScale = 0.2
        inertialCamera.maxScale = 20
        scene.camera = inertialCamera
        scene.addChild(inertialCamera)
    }
    
    func createCamera() {
        let myCamera = SKCameraNode()
        self.camera = myCamera
        addChild(myCamera)
    }
    
    // MARK: - UI Physics
    
    struct PhysicsBitMasks {
        static let sceneBody: UInt32 = 0x1 << 0
        static let sceneField: UInt32 = 0x1 << 1
        static let sceneParticle: UInt32 = 0x1 << 2
        static let sceneParticleCollider: UInt32 = 0x1 << 3
        static let sceneBoundary: UInt32 = 0x1 << 4
        
        static let uiBody: UInt32 = 0x1 << 5
        static let uiField: UInt32 = 0x1 << 6
        static let uiParticle: UInt32 = 0x1 << 7
        static let uiBoundary: UInt32 = 0x1 << 8
    }
    
    func createPhysicalBoundaryForUIBodies(view: SKView, parent: SKNode) {
        let margin: CGFloat = 0
        
        let uiArea = CGRect(
            x: -view.bounds.width/2 - margin/2,
            y: -view.bounds.height/2 - margin/2,
            width: view.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right + margin,
            height: view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom + margin
        )
        
        let uiFrame = SKShapeNode(rect: uiArea)
        uiFrame.alpha = 0
        uiFrame.physicsBody = SKPhysicsBody(edgeLoopFrom: uiArea)
        uiFrame.physicsBody?.categoryBitMask = PhysicsBitMasks.uiBoundary
        uiFrame.physicsBody?.collisionBitMask = PhysicsBitMasks.uiBody
        uiFrame.physicsBody?.fieldBitMask = 0
        uiFrame.physicsBody?.restitution = 0
        uiFrame.physicsBody?.friction = 0
        parent.addChild(uiFrame)
    }
    
    // MARK: - UI Objects
    
    var bodyA = SKSpriteNode()
    var bodyB = SKSpriteNode()
    var springJoint1 = SKPhysicsJointSpring()
    
    func createUIPhysicsJoint(parent: SKNode) {
        /// The first body
        bodyA = SKSpriteNode(color: .systemYellow, size: CGSize(width: 50, height: 50))
        bodyA.physicsBody = SKPhysicsBody(rectangleOf: bodyA.size)
        bodyA.physicsBody?.categoryBitMask = PhysicsBitMasks.uiBody
        bodyA.physicsBody?.collisionBitMask = PhysicsBitMasks.uiBoundary | PhysicsBitMasks.uiBody
        bodyA.physicsBody?.isDynamic = true
        bodyA.physicsBody?.affectedByGravity = false
        bodyA.position = CGPoint(x: 0, y: 100)
        parent.addChild(bodyA)
        
        /// The second body
        bodyB = SKSpriteNode(color: .systemRed, size: CGSize(width: 50, height: 50))
        bodyB.physicsBody = SKPhysicsBody(rectangleOf: bodyB.size)
        bodyB.physicsBody?.categoryBitMask = PhysicsBitMasks.uiBody
        bodyB.physicsBody?.collisionBitMask = PhysicsBitMasks.uiBoundary | PhysicsBitMasks.uiBody
        bodyB.physicsBody?.isDynamic = true
        bodyB.physicsBody?.affectedByGravity = false
        bodyB.position = CGPoint(x: 0, y: -100)
        parent.addChild(bodyB)
        
        /// Spring joints
        springJoint1 = SKPhysicsJointSpring.joint(
            withBodyA: bodyA.physicsBody!,
            bodyB: bodyB.physicsBody!,
            anchorA: bodyA.position,
            anchorB: bodyB.position
        )
        springJoint1.frequency = 1
        springJoint1.damping = 1

        physicsWorld.add(springJoint1)
    }
    
    func createSpringJointAndWheels(parent: SKNode) {
        let anchorSize = CGSize(width: 2, height: 20)
        let bodyRadius: CGFloat = 30
        let dotRadius: CGFloat = 2
        let margin: CGFloat = 4
        
        /// Joint anchors
        let springStart = SKSpriteNode(color: .systemBlue, size: anchorSize)
        springStart.physicsBody = SKPhysicsBody(rectangleOf: springStart.size)
        springStart.physicsBody?.categoryBitMask = PhysicsBitMasks.uiBody
        springStart.physicsBody?.collisionBitMask = PhysicsBitMasks.uiBody | PhysicsBitMasks.uiBoundary
        springStart.position = CGPoint(x: 0, y: 0)
        springStart.zPosition = 10
        parent.addChild(springStart)
        
        let springEnd = SKSpriteNode(color: .systemGreen, size: anchorSize)
        springEnd.physicsBody = SKPhysicsBody(rectangleOf: springEnd.size)
        springEnd.physicsBody?.categoryBitMask = PhysicsBitMasks.uiBody
        springEnd.physicsBody?.collisionBitMask = PhysicsBitMasks.uiBody | PhysicsBitMasks.uiBoundary
        springEnd.position = CGPoint(x: 50, y: -150)
        springEnd.zPosition = 10
        parent.addChild(springEnd)
        
        /// spring joint
        let anchorBPositionInScene: CGPoint
        if let parent = springEnd.parent {
            anchorBPositionInScene = self.convert(springEnd.position, from: parent)
        } else {
            anchorBPositionInScene = .zero
        }
        
        let anchorAPositionInScene: CGPoint
        if let parent = springStart.parent {
            anchorAPositionInScene = self.convert(springStart.position, from: parent)
        } else {
            anchorAPositionInScene = .zero
        }
        
        let springJoint = SKPhysicsJointSpring.joint(
            withBodyA: springStart.physicsBody!,
            bodyB: springEnd.physicsBody!,
            anchorA: anchorAPositionInScene,
            anchorB: anchorBPositionInScene
        )
        springJoint.frequency = 30
        springJoint.damping = 0.5
        physicsWorld.add(springJoint)
        
        /// Wheels
        let wheel1 = SKShapeNode(circleOfRadius: 30)
        wheel1.strokeColor = SKColor(white: 0, alpha: 0.8)
        wheel1.fillColor = SKColor(white: 1, alpha: 0.3)
        wheel1.physicsBody = SKPhysicsBody(circleOfRadius: bodyRadius)
        wheel1.physicsBody?.categoryBitMask = PhysicsBitMasks.uiBody
        wheel1.physicsBody?.collisionBitMask = PhysicsBitMasks.uiBody | PhysicsBitMasks.uiBoundary
        wheel1.physicsBody?.friction = 1
        parent.addChild(wheel1)
        
        let dot1 = SKShapeNode(circleOfRadius: dotRadius)
        dot1.lineWidth = 0
        dot1.fillColor = SKColor(white: 0, alpha: 0.8)
        dot1.position = CGPoint(x: 0, y: bodyRadius - dotRadius - margin)
        dot1.zPosition = 20
        wheel1.addChild(dot1)
        
        let wheel2 = SKShapeNode(circleOfRadius: 30)
        wheel2.strokeColor = SKColor(white: 0, alpha: 0.8)
        wheel2.fillColor = SKColor(white: 1, alpha: 0.3)
        wheel2.physicsBody = SKPhysicsBody(circleOfRadius: bodyRadius)
        wheel2.physicsBody?.categoryBitMask = PhysicsBitMasks.uiBody
        wheel2.physicsBody?.collisionBitMask = PhysicsBitMasks.uiBody | PhysicsBitMasks.uiBoundary
        wheel2.physicsBody?.friction = 1
        wheel2.position = springEnd.position
        parent.addChild(wheel2)
        
        let dot2 = SKShapeNode(circleOfRadius: dotRadius)
        dot2.lineWidth = 0
        dot2.fillColor = SKColor(white: 0, alpha: 0.8)
        dot2.position = CGPoint(x: 0, y: -bodyRadius + dotRadius + margin)
        dot2.zPosition = 20
        wheel2.addChild(dot2)
        
        /// fixed joints that link the anchors with the wheels
        let fixedJointStart = SKPhysicsJointFixed.joint(
            withBodyA: springStart.physicsBody!,
            bodyB: wheel1.physicsBody!,
            anchor: wheel1.position
        )
        physicsWorld.add(fixedJointStart)
        
        let fixedJointEnd = SKPhysicsJointFixed.joint(
            withBodyA: springEnd.physicsBody!,
            bodyB: wheel2.physicsBody!,
            anchor: wheel2.position
        )
        physicsWorld.add(fixedJointEnd)
    }
    
    // MARK: - Scene Objects
    
    func createSceneObjects(parent: SKNode) {
        let sprite0 = SKSpriteNode(color: SKColor(white: 0, alpha: 0.1), size: CGSize(width: 800, height: 800))
        parent.addChild(sprite0)
        
        let sprite = SKSpriteNode(color: SKColor(white: 0, alpha: 0.2), size: CGSize(width: 400, height: 400))
        parent.addChild(sprite)
        
        let sprite2 = SKSpriteNode(color: SKColor(white: 0, alpha: 0.3), size: CGSize(width: 100, height: 100))
        parent.addChild(sprite2)
    }
    
    // MARK: - Helpers
    
    func getNodeScaleInSceneCoordinates(node: SKNode) -> CGPoint {
        var currentNode: SKNode? = node
        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0
        
        while currentNode != nil {
            scaleX *= currentNode!.xScale
            scaleY *= currentNode!.yScale
            currentNode = currentNode?.parent
        }
        
        return CGPoint(x: scaleX, y: scaleY)
    }
    
    // MARK: - Update
    
    override func update(_ currentTime: TimeInterval) {
        updateZoomLabel()
        
        if let inertialCamera = self.camera as? InertialCamera {
            inertialCamera.updateInertia()
        }
    }
    
}
