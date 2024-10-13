/**
 
 # Wheel Spinner
 
 One finger rotation control gizmo in SpriteKit
 
 Achraf Kassioui
 Created: 5 June 2024
 Updated: 9 June 2024
 
 Resources:
 - https://stackoverflow.com/questions/49460481/how-do-i-rotate-a-spritenode-with-a-one-finger-touch-and-drag
 
 */

import SwiftUI
import SpriteKit
import CoreImage.CIFilterBuiltins
import Observation

// MARK: Message Overlay

struct NotificationOverlay: View {
    @Binding var message: String
    @State private var opacity: Double = 0
    @State private var timer: Timer?
    
    public init(message: Binding<String>) {
        self._message = message
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
        .onAppear() {
            showNotification()
        }
        .onChange(of: message) {
            showNotification()
        }
        .opacity(opacity)
        .animation(.easeInOut(duration: 0.1), value: opacity)
    }
    
    private func showNotification() {
        timer?.invalidate()
        opacity = 1
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            opacity = 0
        }
    }
}

// MARK: Inertial Wheel

struct InertialWheel: View {
    @State var rotationAngle: Angle = Angle(degrees: 10)
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 160, height: 160)
                .overlay {
                    Circle()
                        .stroke(.opacity(0.6))
                }
            
            ForEach(0..<2) { i in
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 1, height: 60)
                    .rotationEffect(.degrees(Double(i) * 90))
            }
        }
        .simpleRotationInertia()
        .frame(width: 180, height: 180)
        .rotationEffect(rotationAngle)
        .onChange(of: rotationAngle) {
            print(rotationAngle)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged {_ in
                    print("hello")
                }
                .onEnded {_ in
                    print("yo")
                }
        )
    }
}

// MARK: - SwiftUI View

struct WheelSpinnerView: View {
    @State var myScene = WheelSpinnerScene()
    
    @State private var sceneId = UUID()
    @State private var isPaused = false
    @State private var isGravityON = false
    @State private var isDebugON = false
    @State private var isFullScreen = false
    @State private var message: String = ""
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes]
            )
            .id(sceneId)
            .onAppear {
                sceneId = UUID()
            }
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    NotificationOverlay(message: $myScene.cameraData.scale)
                    Spacer()
                    
                }
                Spacer()
                NotificationOverlay(message: $message)
                InertialWheel()
                menuBar()
            }
            .padding()
        }
        .background(Color.black)
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
    }
    
    private func menuBar() -> some View {
        HStack {
            gravityButton
            playPauseButton
            debugButton
            fullScreenButton
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .stroke(.opacity(0.3), lineWidth: 0.5)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
        )
    }
    
    private var playPauseButton: some View {
        Button(action: {
            isPaused.toggle()
            myScene.pauseScene(isPaused)
            message = isPaused ? "Simulation is paused" : "Simulation is running"
        }) {
            Image(isPaused ? "play-icon" : "pause-icon")
                .renderingMode(.template)
                .foregroundColor(Color.black)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(iconNoBackground())
    }
    
    private var gravityButton: some View {
        Button(action: {
            isGravityON.toggle()
            myScene.sceneGravity = isGravityON
            message = isGravityON ? "Gravity is ON" : "Gravity is OFF"
        }) {
            Image(isGravityON ? "gravity-icon" : "gravity-icon")
                .renderingMode(.template)
                .foregroundColor(isGravityON ? .black : .black.opacity(0.3))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(iconNoBackground())
    }
    
    private var debugButton: some View {
        Button(action: {
            if let view = myScene.view {
                isDebugON.toggle()
                myScene.toggleDebugOptions(view: view, extended: true)
                message = isDebugON ? "Debug options are ON" : "Debug options are OFF"
            }
        }) {
            Image(isDebugON ? "chart-bar-icon" : "chart-bar-icon")
                .renderingMode(.template)
                .foregroundColor(isDebugON ? .black : .black.opacity(0.3))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(iconNoBackground())
    }
    
    private var fullScreenButton: some View {
        Button(action: {
            isFullScreen.toggle()
            myScene.toggleUI(show: isFullScreen)
        }) {
            Image(isFullScreen ? "arrows-close-icon" : "arrows-open-icon")
                .renderingMode(.template)
                .foregroundColor(isFullScreen ? .black : .black.opacity(0.3))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(iconNoBackground())
    }
}

#Preview {
    WheelSpinnerView()
}

// MARK: - Shared State

@Observable
class CameraData {
    var scale: String = ""
    var zoomLevel: String = "100%"
}

// MARK: - SpriteKit

class WheelSpinnerScene: SKScene, InertialCameraDelegate, WheelSpinnerDelegate {
    
    var cameraData = CameraData()
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        view.contentMode = .center
        view.isMultipleTouchEnabled = true
        backgroundColor = SKColor.gray
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        /// this is required when SKScene filters are enabled
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        cleanPhysics()
        
        setupCamera(scale: 1, inertial: true)
        createSceneLayers()
        
        let _ = CGRect(
            x: view.bounds.width * -0.5,
            y: view.bounds.width * -0.5 + (34 + 70 + 180)/2,
            width: view.bounds.width,
            height: view.bounds.width
        )
        createPhysicalBoundaryForSceneBodies(rectangle: self.frame, parent: objectsLayer)
        
        createUI(view: view, parent: uiLayer)
    }
    
    // MARK: Global Variables
    
    var swiftUIMenuBarSize: CGSize = .zero
    
    var sceneGravity = false {
        didSet {
            if sceneGravity { self.physicsWorld.gravity = CGVector(dx: 0, dy: -20) }
            else { self.physicsWorld.gravity = CGVector(dx: 0, dy: 0) }
        }
    }
    
    let uiLayer = SKNode()
    let objectsLayer = SKNode()
    var zoomLabel = SKLabelNode()
    
    func pauseScene(_ isPaused: Bool) {
        self.objectsLayer.isPaused = isPaused
        self.physicsWorld.speed = isPaused ? 0 : 1
    }
    
    func createSceneLayers() {
        guard let camera = camera else {
            print("There is no camera in scene. App will crash.")
            return
        }
        
        uiLayer.zPosition = 9999
        camera.addChild(uiLayer)
        
        objectsLayer.zPosition = 1
        addChild(objectsLayer)
        
        let backgroundTexture = generateGridTexture(cellSize: 75, rows: 30, cols: 30, linesColor: SKColor(white: 0, alpha: 0.3))
        let background = SKSpriteNode(texture: backgroundTexture)
        background.zPosition = -1
        objectsLayer.addChild(background)
    }
    
    // MARK: Camera
    
    func cameraWillScale(to scale: (x: CGFloat, y: CGFloat)) {
        
    }
    
    func cameraDidScale(to scale: (x: CGFloat, y: CGFloat)) {
        let zoomPercentage = 100 / (scale.x)
        let text = String(format: "%.0f%%", zoomPercentage)
        cameraData.scale = text
    }
    
    func cameraDidMove(to position: CGPoint) {
        
    }
    
    func setupCamera(scale: CGFloat, inertial: Bool) {
        if inertial == true {
            let inertialCamera = InertialCamera(scene: self)
            inertialCamera.delegate = self
            inertialCamera.lockRotation = false
            inertialCamera.setTo(position: .zero, xScale: scale, yScale: scale, rotation: 0)
            self.camera = inertialCamera
            //cameraData.scale = "\(self.camera?.xScale ?? 1.0)"
            addChild(inertialCamera)
        } else {
            let camera = SKCameraNode()
            self.camera = camera
            //cameraData.scale = "\(self.camera?.xScale ?? 1.0)"
            addChild(camera)
        }
    }
    
    // MARK: Physics and constraints
    
    func createPhysicalBoundaryForSceneBodies(rectangle: CGRect, parent: SKNode) {
        let boundaryForSceneBodies = SKShapeNode(rect: rectangle)
        boundaryForSceneBodies.lineWidth = 2
        boundaryForSceneBodies.strokeColor = SKColor(white: 0, alpha: 1)
        boundaryForSceneBodies.physicsBody = SKPhysicsBody(edgeLoopFrom: rectangle)
        setupPhysicsCategories(node: boundaryForSceneBodies, as: .sceneBoundary)
        boundaryForSceneBodies.zPosition = -1
        parent.addChild(boundaryForSceneBodies)
    }
    
    func createPhysicalBoundaryForUIBodies(view: SKView, UILayer: SKNode) {
        let bodyExtension: CGFloat = -10
        let uiArea = CGRect(
            x: -view.bounds.width/2 - bodyExtension/2,
            y: -view.bounds.height/2 - bodyExtension/2,
            width: view.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right + bodyExtension,
            height: view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom + bodyExtension
        )
        
        let uiAreaFrame = SKShapeNode(rect: uiArea)
        uiAreaFrame.lineWidth = 0
        uiAreaFrame.physicsBody = SKPhysicsBody(edgeLoopFrom: uiArea)
        setupPhysicsCategories(node: uiAreaFrame, as: .UIBoundary)
        uiAreaFrame.alpha = 0
        UILayer.addChild(uiAreaFrame)
    }
    
    // MARK: Wheel Spinner Protocol Methods
    
    func wheelWillSpin(zRotation: CGFloat) {
        
    }
    
    func wheelDidSpin(zRotation: CGFloat) {
        
    }
    
    func wheelIsTouched(touched: Bool) {
        if touched {
            if let inertialCamera = self.camera as? InertialCamera {
                inertialCamera.lock = true
            }
        } else {
            if let inertialCamera = self.camera as? InertialCamera {
                inertialCamera.lock = false
            }
        }
    }
    
    // MARK: UI
    
    func toggleUI(show: Bool) {
        enumerateChildNodes(withName: "//ui-container", using: { node, _ in
            node.removeAllActions()
            if show == true {
                node.run(SKAction.fadeIn(withDuration: 4/60))
            } else if show == false {
                node.run(SKAction.fadeOut(withDuration: 4/60))
            }
        })
    }
    
    func distributeNodesHorizontally(w: CGFloat, nw: CGFloat, n: Int, m: CGFloat) -> [CGFloat] {
        var positions: [CGFloat] = []
        
        // Calculate the total width occupied by all nodes and margins
        let totalWidth = CGFloat(n) * nw + CGFloat(n - 1) * m
        
        // Calculate the starting x position (leftmost node) to center the nodes in the view
        let startX = -totalWidth / 2 + nw / 2
        
        // Generate the x positions
        for i in 0..<n {
            let x = startX + CGFloat(i) * (nw + m)
            positions.append(x)
        }
        
        return positions
    }
    
    func createUI(view: SKView, parent: SKNode) {
        
        let wheel = createWheelSpinnerControl(view: view)
        wheel.position.y = 260
        parent.addChild(wheel)
        
    }
    
    func createWheelSpinnerControl(view: SKView) -> SKSpriteNode {
        let cornerRadius: CGFloat = 20
        let strokeColor = SKColor(white: 0, alpha: 0.1)
        let fillColor = SKColor(white: 1, alpha: 0.6)
        
        let containerShape = SKShapeNode(rectOf: CGSize(width: 180, height: 180), cornerRadius: cornerRadius)
        containerShape.lineWidth = 0
        containerShape.fillColor = .lightGray
        
        let container = SKSpriteNode(texture: view.texture(from: containerShape))
        container.zPosition = 0
        
        let shadowTexture = generateShadowTexture(
            width: containerShape.frame.size.width,
            height: containerShape.frame.size.height,
            cornerRadius: cornerRadius,
            shadowOffset: CGSize(width: 0, height: 0),
            shadowBlurRadius: 32,
            shadowColor: SKColor(white: 0, alpha: 0.3)
        )
        let shadowSprite = SKSpriteNode(texture: shadowTexture)
        shadowSprite.blendMode = .multiplyAlpha
        shadowSprite.zPosition = -1
        container.addChild(shadowSprite)
        
        let wheel = WheelSpinner(
            view: view,
            radius: 72,
            stroke: strokeColor,
            fill: fillColor
        )
        wheel.delegate = self
        wheel.name = "wheel-spinner"
        wheel.zPosition = 1
        container.addChild(wheel)
        
        return container
    }
    
    // MARK: Mini Map
    
    var shapeWithTexture = SKShapeNode()
    
    func createSpriteFromTexture(view: SKView, parent: SKNode) {
        shapeWithTexture = SKShapeNode(rectOf: CGSize(width: 100, height: 100))
        shapeWithTexture.lineWidth = 1
        shapeWithTexture.strokeColor = SKColor(white: 0, alpha: 0.6)
        shapeWithTexture.fillColor = .white
        shapeWithTexture.zPosition = 10
        shapeWithTexture.position.x = -130
        shapeWithTexture.position.y = 270
        parent.addChild(shapeWithTexture)
        
        let shadowTexture = generateShadowTexture(
            width: view.bounds.width / 4,
            height: view.bounds.height / 4,
            cornerRadius: 0,
            shadowOffset: .zero,
            shadowBlurRadius: 32,
            shadowColor: SKColor(white: 0, alpha: 0.6)
        )
        let shadowSprite = SKSpriteNode(texture: shadowTexture)
        shadowSprite.zPosition = -1
        shapeWithTexture.addChild(shadowSprite)
    }
    
    func updateSpriteFromTexture(view: SKView, node: SKNode) {
        var transform = CGAffineTransform(
            a: 0.25, /// scale Y
            b: 0, /// vertical sheer
            c: 0, /// horizontal sheer
            d: 0.25, /// scale Y
            tx: 0, /// translation X
            ty: 0 /// translation Y
        )
        
        uiLayer.isHidden = true
        if let texture = view.texture(from: node) {
            let path = CGPath(
                rect: CGRect(
                    x: -texture.size().width/2,
                    y: -texture.size().height/2,
                    width: texture.size().width,
                    height: texture.size().height
                ),
                transform: &transform
            )
            shapeWithTexture.path = path
            shapeWithTexture.fillTexture = texture
        }
        uiLayer.isHidden = false
    }
    
    // MARK: Update loop
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.updateInertia()
        }
        
        enumerateChildNodes(withName: "//wheel-spinner", using: { node, _ in
            if let wheel = node as? WheelSpinner {
                wheel.update(currentTime)
            }
        })
        
    }
    
    // MARK: Touch Began
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
}

// MARK: - Wheel Spinner

protocol WheelSpinnerDelegate: AnyObject {
    func wheelIsTouched(touched: Bool)
    func wheelWillSpin(zRotation: CGFloat)
    func wheelDidSpin(zRotation: CGFloat)
}

class WheelSpinner: SKSpriteNode {
    
    // MARK: Properties
    
    weak var view: SKView?
    weak var delegate: WheelSpinnerDelegate?
    private var noGoZone: SKShapeNode?
    
    var wheelRadius: CGFloat
    var strokeColor: SKColor
    var fillColor: SKColor
    
    // MARK: Init
    
    init(view: SKView, radius: CGFloat, stroke: SKColor, fill: SKColor) {
        self.view = view
        self.wheelRadius = radius
        self.strokeColor = stroke
        self.fillColor = fill
        
        super.init(texture: nil, color: .clear, size: CGSize(width: radius*2, height: radius*2))
        self.isUserInteractionEnabled = true
        
        self.texture = getTextureFromShape()
    }
    
    // MARK: Style
    
    func getTextureFromShape() -> SKTexture? {
        guard let view = self.view else { return nil }
        
        let wheel = SKShapeNode(circleOfRadius: self.wheelRadius)
        wheel.lineWidth = 1
        wheel.strokeColor = SKColor(white: 0, alpha: 0.4)
        wheel.fillColor = self.fillColor
        //wheel.fillTexture = generateDotPatternTexture(size: wheel.frame.size, color: .white, pattern: .regular, dotSize: 14)
        
        let axle = SKShapeNode(circleOfRadius: 26)
        axle.isUserInteractionEnabled = true
        axle.lineWidth = 1
        axle.strokeColor = SKColor(white: 0, alpha: 0.4)
        axle.fillColor = SKColor.lightGray
        wheel.addChild(axle)
        
        let anchorX = SKShapeNode(rectOf: CGSize(width: 8, height: 1))
        anchorX.lineWidth = 0
        anchorX.fillColor = SKColor(white: 0, alpha: 0.6)
        anchorX.zRotation = .pi * 0.25
        wheel.addChild(anchorX)
        
        let anchorY = SKShapeNode(rectOf: CGSize(width: 1, height: 8))
        anchorY.lineWidth = 0
        anchorY.fillColor = SKColor(white: 0, alpha: 0.6)
        anchorY.zRotation = .pi * 0.25
        wheel.addChild(anchorY)
        
        let handle = SKShapeNode(circleOfRadius: 21)
        handle.fillColor = SKColor(red: 247/255, green: 208/255, blue: 84/255, alpha: 1)
        handle.strokeColor = SKColor(white: 0, alpha: 0.6)
        handle.lineWidth = 3
        handle.position.y = wheelRadius - handle.frame.width/2
        wheel.addChild(handle)
        
        self.noGoZone = axle
        
        let texture = view.texture(from: wheel)
        return texture
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Protocol
    
    var isTouched = false {
        didSet {
            delegate?.wheelIsTouched(touched: isTouched)
        }
    }
    
    override var zRotation: CGFloat {
        willSet {
            delegate?.wheelWillSpin(zRotation: self.zRotation)
        }
        didSet {
            delegate?.wheelDidSpin(zRotation: self.zRotation)
        }
    }
    
    // MARK: API
    
    private func calculateRotationAngle(start: CGPoint, end: CGPoint) -> CGFloat {
        let center = self.position
        let startVector = CGVector(dx: start.x - center.x, dy: start.y - center.y)
        let endVector = CGVector(dx: end.x - center.x, dy: end.y - center.y)
        
        let angleDifference = atan2(startVector.dy * endVector.dx - startVector.dx * endVector.dy,
                                    startVector.dx * endVector.dx + startVector.dy * endVector.dy)
        // Inverted to match the natural touch rotation direction
        return -angleDifference
    }
    
    func isInsideNoGoZone(touch: UITouch) {
        guard let parent = self.parent, let noGoZone = noGoZone else { return }
        
        let positionInSelf = touch.location(in: self)
        let positionInParent = touch.location(in: parent)
        
        /// Check if the touch is inside the no-go zone
        if noGoZone.contains(positionInSelf) {
            self.previousTouchPosition = positionInParent
            return
        }
    }
    
    // MARK: Inertial rotation
    
    var angularVelocityFactor: CGFloat = 1
    
    func update(_ currentTime: TimeInterval) {
        
        angularVelocity *= angularVelocityFactor
        
        if (abs(angularVelocity) < 0.001) {
            angularVelocity = 0
        }
        
        self.zRotation += angularVelocity
        
    }
    
    // MARK: Touch
    
    private var previousTouchPosition: CGPoint = .zero
    private var previousTouchTime: TimeInterval = 0
    private var previousAngle: CGFloat = 0
    private var angularVelocity: CGFloat = 0
    private var minimumDurationForInertia: Double = 0.02
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            isTouched = true
            
            if let parent = self.parent {
                angularVelocity = 0
                previousTouchPosition = touch.location(in: parent)
                previousTouchTime = touch.timestamp
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, let parent = self.parent {
            
            /// Update rotation
            let touchLocation = touch.location(in: parent)
            let angle = calculateRotationAngle(start: previousTouchPosition, end: touchLocation)
            self.zRotation += angle
            
            /// Reset position and time state
            previousTouchTime = touch.timestamp
            previousTouchPosition = touchLocation
            previousAngle = angle
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, let parent = self.parent {
            isTouched = false
            
            let distance = touch.location(in: parent) - previousTouchPosition
            let deltaTime = touch.timestamp - previousTouchTime
            let velocity = distance.length() / deltaTime
            print(distance)
            let direction: CGFloat = previousAngle >= 0 ? 1 : -1
            angularVelocity = direction * velocity/1000
            
        }
    }
    
}
