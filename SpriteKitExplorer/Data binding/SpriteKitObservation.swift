/**
 
 # SpriteKit and Observation
 
 A minimal setup to link SwiftUI and SpriteKit through Observation.
 
 Achraf Kassioui
 Created: 9 June 2024
 Updated: 11 June 2024
 
 */
import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct InfoDisplay: View {
    var message: String
    @State private var opacity: Double = 0
    @State private var offset: Double = -10
    @State private var timer: Timer?
    
    public init(message: String) {
        self.message = message
    }
    
    var body: some View {
        VStack {
            if !message.isEmpty {
                HStack {
                    Text(message)
                        .foregroundStyle(.white)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.black.opacity(0.8))
                        .shadow(color: .black.opacity(0.3), radius: 12, y: 10)
                )
            }
        }
        .onChange(of: message) {
            showInfo()
        }
        .opacity(opacity)
        .animation(.easeInOut(duration: 0.1), value: opacity)
        .offset(CGSize(width: 0, height: offset))
        .animation(.snappy, value: offset)
    }
    
    private func showInfo() {
        timer?.invalidate()
        opacity = 1
        offset = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            opacity = 0
            offset = -10
        }
    }
}

struct SpriteKitObservationView: View {
    var myScene = SpriteKitObservationScene()
    
    var body: some View {
        ZStack {
            SpriteView(scene: myScene, debugOptions: [.showsFPS])
                .ignoresSafeArea()
            VStack {
                InfoDisplay(message: myScene.myViewModel.cameraZoom)
                Spacer()
            }
            
            InfoDisplay(message: myScene.myViewModel.positionDisplay)
                .position(myScene.myViewModel.positionInView)
                .offset(CGSize(
                        width: 0,
                        height: -myScene.myViewModel.model.sprite.frame.height - (47)
                    )
                )
        }
    }
}

#Preview {
    SpriteKitObservationView()
}

// MARK: - Observed Data

struct MyViewModel {
    var model = MyDataModel()
    
    var positionDisplay: String {
        return "x: \(Int(model.positionInScene.x)), y: \(Int(model.positionInScene.y))"
    }
    
    var positionInView: CGPoint {
        return model.positionInView
    }
    
    var cameraZoom: String {
        let zoomPercentage = 100 / (model.cameraXScale)
        let text = String(format: "Zoom: %.0f%%", zoomPercentage)
        return text
    }
}

@Observable
class MyDataModel {
    var positionInScene: CGPoint = .zero
    var positionInView: CGPoint = CGPoint(x: -1000, y: -1000)
    var cameraXScale: CGFloat = 1
    
    var camera = InertialCamera()
    var sprite = SKSpriteNode()
}

// MARK: - SpriteKit

class SpriteKitObservationScene: SKScene, InertialCameraDelegate {
    
    // MARK: Scene Setup
    
    var myViewModel = MyViewModel()
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        
        let grid = SKSpriteNode(texture: generateGridTexture(cellSize: 75, rows: 30, cols: 30, linesColor: SKColor(white: 0, alpha: 0.3)))
        addChild(grid)
        
        let inertialCamera = myViewModel.model.camera
        inertialCamera.delegate = self
        inertialCamera.parentScene = self
        camera = inertialCamera
        addChild(inertialCamera)
        
        let sprite = SKSpriteNode(color: .systemYellow, size: CGSize(width: 75, height: 75))
        myViewModel.model.sprite = sprite
        addChild(sprite)
    }
    
    func moveSprite(sprite: SKSpriteNode, to touchLocation: CGPoint) {
        sprite.position = touchLocation - touchOffset
        myViewModel.model.positionInScene = sprite.position
        myViewModel.model.positionInView = convertPoint(toView: sprite.position)
    }
    
    // MARK: Camera Protocol
    
    func cameraWillScale(to scale: (x: CGFloat, y: CGFloat)) {
        
    }
    
    func cameraDidScale(to scale: (x: CGFloat, y: CGFloat)) {
        myViewModel.model.cameraXScale = scale.x
    }
    
    func cameraDidMove(to position: CGPoint) {
        myViewModel.model.positionInView = convertPoint(toView: myViewModel.model.sprite.position)
    }
    
    // MARK: Touch Events
    
    var touchOffset: CGPoint = .zero
    var isSpriteDragged = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            let node = atPoint(touchLocation)
            if node == myViewModel.model.sprite {
                isSpriteDragged = true
                myViewModel.model.camera.lock = true
                touchOffset = touchLocation - node.position
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if isSpriteDragged == true {
                let touchLocation = touch.location(in: self)
                moveSprite(sprite: myViewModel.model.sprite, to: touchLocation)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isSpriteDragged = false
        myViewModel.model.camera.lock = false
    }
}
