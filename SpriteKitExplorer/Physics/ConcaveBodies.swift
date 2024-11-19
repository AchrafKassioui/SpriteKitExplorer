/**
 
 # Concave Physics Bodies
 
 Achraf Kassioui
 Created 7 November 2024
 updated 7 November 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

struct ConcaveBodiesView: View {
    var myScene = ConcaveBodiesScene()
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene
                ,debugOptions: [.showsPhysics]
            )
            .ignoresSafeArea()
        }
        .background(Color(SKColor.black))
    }
}

#Preview {
    ConcaveBodiesView()
}

class ConcaveBodiesScene: SKScene {
    
    // MARK: Scene Setup
    
    let fillColor = SKColor(white: 0, alpha: 0.3)
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.speed = 0.05 /// slow down the physics simulation to see what is happening
        
        let inertialCamera = InertialCamera(scene: self)
        self.camera = inertialCamera
        inertialCamera.setScale(0.33)
        addChild(inertialCamera)
        
        /**
         
         Physics bodies created with paths can not by concave.
         The following path is from Apple Documentation: https://developer.apple.com/documentation/spritekit/sknode/getting_started_with_physics_bodies
         It defines a concave polygon. However, collision and hit detection tests show that the concave region of the shape acts as if it were part of the physics body, which it should not.
         For example, the black square is positionned inside the concave part of the spaceship body. As soon as the simulation starts, it is pushed away.
         
         The only was to define a concave physics body seems to either:
         - Use texture based physics bodies
         - Make a concave shape with the union of convex shapes, using compound bodies or physics joints.
         
         */
        let spaceShip = SKSpriteNode(color: .systemYellow, size: CGSize(width: 10, height: 10))
        let spaceShipPath = CGMutablePath()
        spaceShipPath.addLines(between: [CGPoint(x: -5, y: 37), CGPoint(x: 5, y: 37), CGPoint(x: 10, y: 20),
                                CGPoint(x: 56, y: -5), CGPoint(x: 37, y: -35), CGPoint(x: 15, y: -30),
                                CGPoint(x: 12, y: -37), CGPoint(x: -12, y: -37), CGPoint(x: -15, y: -30),
                                CGPoint(x: -37, y: -35), CGPoint(x: -56, y: -5), CGPoint(x: -10, y: 20),
                                CGPoint(x: -5, y: 37)])
        spaceShipPath.closeSubpath()
        spaceShip.physicsBody = SKPhysicsBody(polygonFrom: spaceShipPath)
        addChild(spaceShip)
        
        let sprite = SKSpriteNode(color: .black, size: CGSize(width: 10, height: 10))
        sprite.position = CGPoint(x: -24, y: 24)
        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        addChild(sprite)
        
        let ground = SKSpriteNode(color: .black, size: CGSize(width: 1000, height: 10))
        ground.position.y = -400
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        addChild(ground)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            physicsWorld.enumerateBodies(at: touchLocation, using: { body, stop in
                print(body)
            })
        }
    }
}
