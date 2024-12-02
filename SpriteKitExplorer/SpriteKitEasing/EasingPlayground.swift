/**
 
 # Easing Playground
 
 Achraf Kassioui
 Created: 17 October 2024
 Updated: 17 October 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - Live preview

struct EasingPlaygroundView: View {
    
    var body: some View {
        SpriteView(
            scene: EasingPlaygroundScene(),
            preferredFramesPerSecond: 120,
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
            debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS]
        )
        .ignoresSafeArea()
    }
}

#Preview {
    EasingPlaygroundView()
}

// MARK: - Demo Scene

class EasingPlaygroundScene: SKScene {
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        backgroundColor = SKColor.gray
        
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.lock = false
        camera = inertialCamera
        addChild(inertialCamera)
        
        Task {
            let gridImage = await generateGridTexture(cellSize: 50, rows: 20, cols: 10, linesColor: UIColor(white: 1, alpha: 0.2))
            
            await MainActor.run {
                let backgroundSprite = SKSpriteNode(texture: SKTexture(image: gridImage))
                addChild(backgroundSprite)
            }
        }
        
        createAction()
    }
    
    func createAction() {
        let movingShape = SKShapeNode(rectOf: CGSize(width: 10, height: 60), cornerRadius: 4)
        movingShape.lineWidth = 0
        movingShape.fillColor = .systemYellow
        movingShape.zPosition = 2
        addChild(movingShape)
        
        let arcCurve = UIBezierPath(
            arcCenter: CGPoint(x: 0, y: 0),
            radius: 150,
            startAngle: CGFloat(160).degreesToRadians(),
            endAngle: CGFloat(20).degreesToRadians(),
            clockwise: true
        )
        
        /// Dashed path
        let _ = arcCurve.cgPath.copy(dashingWithPhase: 0, lengths: [3, 10])
        
        let pathShape = SKShapeNode(path: arcCurve.cgPath)
        pathShape.lineWidth = 30
        pathShape.lineCap = .round
        pathShape.strokeColor = .darkGray
        pathShape.zPosition = 1
        addChild(pathShape)
        
        let followPathAction = SKAction.follow(
            arcCurve.cgPath,
            asOffset: false,
            orientToPath: true,
            duration: 3
        )
        followPathAction.timingFunction = QuadraticEaseInOut(_:)
        
        let fadeIn = SKAction.fadeIn(withDuration: 1)
        fadeIn.timingMode = .easeIn
        let fadeOut = SKAction.fadeOut(withDuration: 1)
        fadeOut.timingMode = .easeOut
        let waitAction = SKAction.wait(forDuration: 0.5)
        let groupAction = SKAction.group([
            SKAction.sequence([waitAction, fadeIn, fadeOut, waitAction]),
            followPathAction
        ])
        movingShape.run(SKAction.repeatForever(groupAction))
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let inerterialCamera = camera as? InertialCamera {
            inerterialCamera.update()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            if let inerterialCamera = camera as? InertialCamera {
                inerterialCamera.stopInertia()
            }
        }
    }
    
}
