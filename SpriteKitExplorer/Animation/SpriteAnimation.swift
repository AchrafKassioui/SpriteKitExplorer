/**
 
 # Sprite Animation
 
 Animating sprites in SpriteKit
 
 Created: 20 March 2024
 
 */

import SwiftUI
import SpriteKit

struct SpriteAnimationView: View {
    var myScene = SpriteAnimationScene()
    
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

#Preview {
    SpriteAnimationView()
}

class SpriteAnimationScene: SKScene {
    
    // MARK: Scene setup
    
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .gray
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.zPosition = 999
        camera = inertialCamera
        addChild(inertialCamera)
        
        setupObjects()
    }
    
    func setupObjects() {
        guard let view = view else { return }
        
        let margin = 50.0
        let horizontalAmount = Int(view.bounds.height / margin) / 2
        let verticalAmount = Int(view.bounds.width / margin) / 2
        
        let initialSize = CGSize(width: 10, height: 10)
        let color = UIColor(white: 1, alpha: 0.2)
        
        /// horizontal lines
        for i in -horizontalAmount...horizontalAmount {
            let sprite = SKSpriteNode(color: color, size: initialSize)
            sprite.physicsBody = SKPhysicsBody(rectangleOf: initialSize)
            sprite.physicsBody?.usesPreciseCollisionDetection = true
            sprite.position.y = CGFloat(i) * margin
            sprite.name = "horizontal_line_\(i+1)"
            addChild(sprite)
        }
        
        /// vertical lines
        for i in -verticalAmount...verticalAmount {
            let sprite = SKSpriteNode(color: color, size: initialSize)
            sprite.physicsBody = SKPhysicsBody(rectangleOf: initialSize)
            sprite.physicsBody?.usesPreciseCollisionDetection = true
            sprite.position.x = CGFloat(i) * margin
            sprite.name = "vertical_line_\(i+1)"
            addChild(sprite)
        }
    }
    
    // MARK: Sprite animation
    
    func growHorizontally(node: SKSpriteNode) {
        guard let widthTarget = view?.bounds.width else { return }
        let scaleFactor = widthTarget / node.size.width
        
        let growAction = SKAction.scaleX(by: scaleFactor, y: 1, duration: 0.3)
        growAction.timingMode = .easeIn
        node.run(growAction)
        print("grown horizontally")
    }
    
    func growVertically(node: SKSpriteNode) {
        guard let heightTarget = view?.bounds.height else { return }
        let scaleFactor = heightTarget / node.size.width
        
        let growAction = SKAction.scaleX(by: 1, y: scaleFactor, duration: 0.3)
        growAction.timingMode = .easeIn
        node.run(growAction)
    }
    
    // MARK: Keyframes
    
    var simulationTime: TimeInterval = 0
    var keyframes = [TimeInterval: Any]()
    
    override func update(_ currentTime: TimeInterval) {
        simulationTime = currentTime
    }
    
    // MARK: Handle touch
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let scene = self.scene else { return }
        
        for touch in touches {
            let touchLocation = touch.location(in: scene)
            let majorRadius = touch.majorRadius
            
            self.enumerateChildNodes(withName: "horizontal_line*") { node, stop in
                let distance = sqrt(pow(node.position.x - touchLocation.x, 2) + pow(node.position.y - touchLocation.y, 2))
                
                if distance <= majorRadius {
                    self.growHorizontally(node: node as! SKSpriteNode)
                }
            }
            
            self.enumerateChildNodes(withName: "vertical_line*") { node, stop in
                let distance = sqrt(pow(node.position.x - touchLocation.x, 2) + pow(node.position.y - touchLocation.y, 2))
                
                if distance <= majorRadius {
                    self.growVertically(node: node as! SKSpriteNode)
                }
            }
        }
    }


    
}
