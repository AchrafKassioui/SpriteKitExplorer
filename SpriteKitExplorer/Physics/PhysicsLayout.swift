/**
 
 # Physics Layout
 
 Achraf Kassioui
 Created: 24 April 2024
 Updated: 24 April 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - Live preview

struct PhysicsLayoutView: View {
    @State private var sceneId = UUID()
    
    var body: some View {
        SpriteView(
            scene: PhysicsLayoutScene(),
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
            debugOptions: [.showsFPS, .showsDrawCount, .showsNodeCount, .showsFields]
        )
        /// force recreation using the unique ID
        .id(sceneId)
        .onAppear {
            /// generate a new ID on each appearance
            sceneId = UUID()
        }
        .ignoresSafeArea()
        .background(.black)
    }
}

#Preview {
    PhysicsLayoutView()
}

class PhysicsLayoutScene: SKScene {
    
    // MARK: - Scene setup
    
    override func didMove(to view: SKView) {
        /// configure view
        size = view.bounds.size
        scaleMode = .resizeFill
        view.contentMode = .center
        backgroundColor = SKColor(red: 0.89, green: 0.89, blue: 0.84, alpha: 1)
        backgroundColor = .darkGray
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        view.isMultipleTouchEnabled = true
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.speed = 1
        
        /// create background
        let gridTexture = generateGridTexture(cellSize: 150, rows: 10, cols: 10, linesColor: SKColor(white: 1, alpha: 0.3))
        let gridbackground = SKSpriteNode(texture: gridTexture)
        gridbackground.zPosition = -1
        addChild(gridbackground)
        
        /// create camera
        let inertialCamera = InertialCamera(scene: self)
        camera = inertialCamera
        addChild(inertialCamera)
        inertialCamera.zPosition = 99999
        inertialCamera.lockPan = true
        //inertialCamera.lockRotation = true
        
        ///
        createPhysicalBoundaries(view)
        createButtonContainer()
        createPhysicalButton(view)
    }
    
    // MARK: - UI
    
    func createButtonContainer() {
        let container = SKShapeNode(rectOf: CGSize(width: 62, height: 180), cornerRadius: 12)
        container.name = "draggable"
        container.lineWidth = 1
        container.strokeColor = SKColor(white: 0, alpha: 1)
        //container.physicsBody = SKPhysicsBody(rectangleOf: container.frame.size)
        container.physicsBody?.isDynamic = false
        camera?.addChild(container)
        
        let dragHandle = SKShapeNode(rectOf: CGSize(width: 62, height: 44), cornerRadius: 12)
        dragHandle.lineWidth = 0
        dragHandle.fillColor = SKColor(white: 0, alpha: 1)
        dragHandle.position.y = container.frame.minY - dragHandle.frame.height/2
        container.addChild(dragHandle)
    }
    
    func createPhysicalButton(_ view: SKView) {
        let physicalButton = ButtonPhysical(
            view: view,
            shape: .round,
            size: CGSize(width: 60, height: 60),
            iconInactive: SKTexture(imageNamed: "viewfinder"),
            iconActive: SKTexture(imageNamed: "viewfinder"),
            iconSize: CGSize(width: 24, height: 24),
            theme: .dark,
            isPhysical: true,
            onTouch: {
                print("Button action called")
                if let inertialCamera = self.camera as? InertialCamera {
                    inertialCamera.stopInertia()
                    inertialCamera.setTo(position: .zero, xScale: 1, yScale: 1, rotation: 0)
                }
            }
        )
        physicalButton.name = "draggable"
        addChild(physicalButton)
    }
    
    func createPhysicalBoundaries(_ view: SKView) {
        let physicsBoundaries = CGRect(
            x: -view.frame.width / 2,
            y: -view.frame.height / 2,
            width: view.frame.width,
            height: view.frame.height
        )
        
        let physicalFrame = SKShapeNode(rect: physicsBoundaries)
        physicalFrame.lineWidth = 3
        physicalFrame.strokeColor = SKColor(white: 0, alpha: 0.9)
        physicalFrame.physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBoundaries)
        physicalFrame.isUserInteractionEnabled = false
        physicalFrame.zPosition = -1
        physicalFrame.physicsBody?.isDynamic = false
        addChild(physicalFrame)
    }
    
    // MARK: - Update loop
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.updateInertia()
        }
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
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
