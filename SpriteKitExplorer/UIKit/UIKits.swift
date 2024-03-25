/**
 
 # UIKit in SpriteKit
 
 Trying out various UIKit methods and API from within SpriteKit code
 
 Created: 18 March 2024
 Updated: 18 March 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct UIKitView: View {
    var myScene = UIKitScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                preferredFramesPerSecond: 120,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount]
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    UIKitView()
}

// MARK: - SpriteKit

class UIKitScene: SKScene {
    
    // MARK: Scene setup
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .darkGray
    }
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        scene?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        physicsWorld.speed = 1
        physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        setupCamera()
        addObjects()
        addViews()
    }
    
    func setupCamera() {
        let camera = SKCameraNode()
        let viewSize = view?.bounds.size
        camera.xScale = (viewSize!.width / size.width)
        camera.yScale = (viewSize!.height / size.height)
        addChild(camera)
        scene?.camera = camera
        camera.setScale(1)
    }
    
    func addObjects() {
        var i = -70
        for _ in 0...5 {
            let sprite = SKSpriteNode(color: .systemRed, size: CGSize(width: 60, height: 60))
            sprite.position = CGPoint(x: -100 + i, y: 100 - i)
            i += 70
            addChild(sprite)
        }
    }
    
    func addViews() {
        guard let view = view else { return }
        
        let myUIKitView = createUIView()
        view.addSubview(myUIKitView)
        myUIKitView.center = view.center
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        label.text = "  UIKit view"
        label.font = UIFont(name: "Menlo-Bold", size: 24)
        myUIKitView.addSubview(label)
    }
}

func createUIView() -> UIView {
    let myView = UIView()
    myView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
    myView.backgroundColor = UIColor(white: 1, alpha: 0.7)
    return myView
}

func animateView(view: UIView) {
    UIView.animate(withDuration: 1, animations: {
        view.transform = CGAffineTransform(scaleX: 2, y: 2)
    })
}

func transformView(view: UIView) {
    view.transform = CGAffineTransform(rotationAngle: 1)
}

func animateViewWithSKAction(view: UIView, container: SKNode) {
    let rotationAction = SKAction.customAction(withDuration: 1) {_, elapsedTime in
        view.transform = CGAffineTransform(rotationAngle: 2 * .pi * elapsedTime)
    }
    container.run(SKAction.repeatForever(rotationAction))
}
