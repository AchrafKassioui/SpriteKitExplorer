/**
 
 # Combine + SwiftUI + SpriteKit
 
 A setup that links a SwiftUI and SpriteKit using the Combine framework.
 The user can type text through a SwiftUI interface, and SpriteKit draws and updates the text.
 The user can also pan and zoom the camera, and double tap to reset the camera.
 
 Created: 7 December 2023, starting from John Knowles' code here: https://gist.github.com/overlair/cd116c7f991c6065c0c0635a2e94dcd4
 Updated: 19 January 2024
 
 */

import SwiftUI
import SpriteKit
import Combine


// MARK: - Model for text

class TextModel: ObservableObject {
    @Published var textFieldContent: String = ""
}

// MARK: - SwiftUI

struct Combine: View {
    @StateObject private var textViewModel = TextModel()
    
    var body: some View {
        let myScene = CombineTextScene(size: CGSize(width: 3000, height: 3000), textViewModel: textViewModel)
        
        ZStack {
            SpriteView(
                scene: myScene,
                preferredFramesPerSecond: 120,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount, .showsPhysics]
            )
                .ignoresSafeArea()
            VStack {
                Spacer()
                TextField("Type...", text: $textViewModel.textFieldContent)
                    .multilineTextAlignment(.center)
                    .padding(10)
                    //.keyboardType(.alphabet)
                    //.disableAutocorrection(true)
                    .background(.thickMaterial)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
    }
}

// MARK: - SpriteKit

class CombineTextScene: SKScene, UIGestureRecognizerDelegate {
    
    /// general
    var intendedSceneSize: CGSize
    
    /// placeholder for the data model that will be passed in by the scene initializer
    var textViewModel: TextModel
    /// A Combine expectation. Seach for `AnyCancellable`
    private var cancellables: Set<AnyCancellable> = []
    
    /// camera rig
    var initialCameraPosition: CGPoint?
    var initialCameraScale: CGFloat?
    var pinchLocationInScene: CGPoint?
    var maxZoomIn: CGFloat = 0.25
    var maxZoomOut: CGFloat = 4
    var panInertiaTimer: Timer?
    var panVelocity: CGPoint?
    var previousRecordedTranslation: CGPoint?
    var lastRecordedTranslation: CGPoint?
    
    /// a hack to circumvent SpriteKit's blurry text when zoomed in
    /// a SKLabelNode will render blurry under zoom
    /// therefore we use multi-sampling to prevent blurriness
    let textScaleFactor: CGFloat = 3.0
    
    // MARK: init
    
    init(size: CGSize, textViewModel: TextModel) {
        self.intendedSceneSize = size
        self.textViewModel = textViewModel
        super.init(size: size)
        self.scaleMode = .resizeFill
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: didMove
    
    override func didMove(to view: SKView) {
        createBackground()
        setupMainCamera()
        addObjects()
        setupDataModel()
        
        // pan gesture
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(gesture:)))
        view.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = self
        
        // pinch gesture
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(gesture:)))
        view.addGestureRecognizer(pinchGestureRecognizer)
        pinchGestureRecognizer.delegate = self
        
        // double tap
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapGesture(gesture:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGestureRecognizer)
        doubleTapGestureRecognizer.delegate = self
    }
    
    func createBackground() {
        self.backgroundColor = SKColor.white
        let gridPatternTexture = SKTexture(imageNamed: "gridPattern")
        let xRepeats = Int(intendedSceneSize.width / gridPatternTexture.size().width)
        let yRepeats = Int(intendedSceneSize.height / gridPatternTexture.size().height)
        // Start the pattern from negative half the scene dimensions
        for i in -xRepeats/2..<xRepeats/2 {
            for j in -yRepeats/2..<yRepeats/2 {
                let backgroundPattern = SKSpriteNode(texture: gridPatternTexture)
                backgroundPattern.position = CGPoint(
                    x: CGFloat(i) * gridPatternTexture.size().width,
                    y: CGFloat(j) * gridPatternTexture.size().height
                )
                backgroundPattern.anchorPoint = CGPoint(x: 0, y: 0)
                addChild(backgroundPattern)
            }
        }
    }
    
    func setupMainCamera() {
        let camera = SKCameraNode()
        let viewSize = view?.bounds.size
        camera.xScale = (viewSize!.width / size.width)
        camera.yScale = (viewSize!.height / size.height)
        addChild(camera)
        scene?.camera = camera
    }
    
    /// Combine methods
    func setupDataModel() {
        textViewModel.$textFieldContent
            .sink { [weak self] newText in
                self?.updateText(newText)
            }
            .store(in: &cancellables)
    }
    
    // MARK: scene objects
    
    func updateText(_ newText: String) {
        self.enumerateChildNodes(withName: "myText") { node, _ in
            if let labelNode = node as? SKLabelNode {
                labelNode.text = newText
            }
        }
    }
    
    func addObjects() {
        let redSquare = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        redSquare.position = CGPoint.zero
        redSquare.zRotation = 0.5
        redSquare.zPosition = 10
        addChild(redSquare)
        continuouslyRotate(redSquare)
        
        let myText = SKLabelNode()
        /// render text at a higher resolution internally
        myText.fontSize = 32 * textScaleFactor
        myText.name = "myText"
        myText.text = "Hello"
        myText.fontName = "Impact"
        myText.fontColor = SKColor.black
        myText.position = CGPoint(x: .zero, y: .zero + 60)
        /// scale down the text internally before drawing.
        /// this is the multi-sampling hack
        myText.xScale = 1 / textScaleFactor
        myText.yScale = 1 / textScaleFactor
        myText.zPosition = 11
        addChild(myText)
    }
    
    func continuouslyRotate(_ sprite: SKSpriteNode) {
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 10.0)
        let continuousRotation = SKAction.repeatForever(rotateAction)
        sprite.run(continuousRotation)
    }
    
    /**
     
     # Camera handling
     
     Below is the logic that handles camera panning and zooming.
     It works, but it's not great. The pinch is okay, but the inertial panning uses a Timer instead of SpriteKit native update loop.
     Using the update loop for inertial panning should provide a smoother behavior.
     
     */

    override func update(_ currentTime: TimeInterval) {
        /// Panning logic should this game loop
    }
    
    // MARK: panning
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc private func handlePanGesture(gesture: UIPanGestureRecognizer) {
        guard let camera = camera else { return }
        
        let translation = gesture.translation(in: view)
        let scaledTranslation = CGPoint(
            x: translation.x * camera.xScale,
            y: translation.y * camera.yScale
        )
        
        switch gesture.state {
        case .began:
            initialCameraPosition = camera.position
            
        case .changed:
            guard let initialCameraPosition = initialCameraPosition else { return }
            let newPosition = CGPoint(
                x: initialCameraPosition.x - scaledTranslation.x,
                y: initialCameraPosition.y + scaledTranslation.y
            )
            camera.position = newPosition
            
            if lastRecordedTranslation != nil {
                previousRecordedTranslation = lastRecordedTranslation
            }
            lastRecordedTranslation = scaledTranslation
            
        case .ended:
            guard let lastTranslation = lastRecordedTranslation, let previousTranslation = previousRecordedTranslation else { return }
            let translationDiff = hypot(lastTranslation.x - previousTranslation.x, lastTranslation.y - previousTranslation.y)
            
            /// Check if the translation has moved significantly. For example, more than 2 points.
            if translationDiff > 2 {
                /// coordinates are negated to convert from UIView coordinates to SpriteKit coordinates
                panVelocity = CGPoint(
                    x: -gesture.velocity(in: view).x,
                    y: -gesture.velocity(in: view).y
                )
                panInertiaTimer?.invalidate()
                panInertiaTimer = Timer.scheduledTimer(
                    timeInterval: 0.016,
                    target: self,
                    selector: #selector(applyPanInertia),
                    userInfo: nil,
                    repeats: true
                )
            }
            
        default:
            break
        }
    }
    
    @objc func applyPanInertia() {
        guard let camera = camera, let panVelocity = panVelocity else { return }
        
        /// This simulates friction, adjust as needed
        let inertiaFactor: CGFloat = 0.95
        
        let scaledVelocity = CGPoint(
            x: panVelocity.x * camera.xScale * 0.01,
            y: -panVelocity.y * camera.yScale * 0.01
        )
        
        camera.position = CGPoint(
            x: camera.position.x + scaledVelocity.x,
            y: camera.position.y + scaledVelocity.y
        )
        
        /// Reduce the velocity for friction
        self.panVelocity?.x *= inertiaFactor
        self.panVelocity?.y *= inertiaFactor
        
        /// Stop when velocity is negligible
        if abs(self.panVelocity!.x) < 1 && abs(self.panVelocity!.y) < 1 {
            stopPanning()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        stopPanning()
    }
    
    func stopPanning() {
        panInertiaTimer?.invalidate()
        panInertiaTimer = nil
    }
    
    // MARK: pinching
    
    @objc private func handlePinchGesture(gesture: UIPinchGestureRecognizer) {
        guard let camera = camera else { return }
        
        switch gesture.state {
        case .began:
            initialCameraScale = camera.xScale
            
            /// Calculate the pinch's midpoint in the scene
            let pinchMidpointInView = gesture.location(in: view)
            pinchLocationInScene = convertPoint(fromView: pinchMidpointInView)
            
        case .changed:
            guard let pinchLocationInScene = pinchLocationInScene, let initialCameraScale = initialCameraScale else { return }
            
            /// Calculate the new scale based directly on the gesture's scale
            var newScale = initialCameraScale / gesture.scale
            
            if newScale >= maxZoomOut {
                newScale = maxZoomOut
            } else if newScale <= maxZoomIn {
                newScale = maxZoomIn
            }
            
            /// Calculate the zoom factor based on the new scale relative to the initial scale
            let zoomFactor = newScale / camera.xScale
            
            /// Calculate the new camera position
            let newCamPosX = pinchLocationInScene.x + (camera.position.x - pinchLocationInScene.x) * zoomFactor
            let newCamPosY = pinchLocationInScene.y + (camera.position.y - pinchLocationInScene.y) * zoomFactor
            
            /// Update camera's position and scale
            camera.position = CGPoint(x: newCamPosX, y: newCamPosY)
            camera.xScale = newScale
            camera.yScale = newScale
            
        default:
            pinchLocationInScene = nil
        }
    }
    
    // MARK: double tap
    
    @objc private func handleDoubleTapGesture(gesture: UITapGestureRecognizer) {
        guard let camera = camera else { return }
        
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.3)
        scaleAction.timingMode = .easeInEaseOut
        
        let moveAction = SKAction.move(to: CGPoint.zero, duration: 0.3)
        moveAction.timingMode = .easeInEaseOut
        
        let groupActions = SKAction.group([scaleAction, moveAction])
        camera.run(groupActions)
    }
    
}

#Preview {
    Combine()
}
