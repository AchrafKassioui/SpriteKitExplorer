/**
 
 # SpriteKit Inertial Camera - Draft 00
 
 Achraf Kassioui
 Created: 27 March 2024
 Updated: 30 March 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - Live preview

struct CameraBasicsView: View {
    var myScene = CameraBasicsScene()
    
    var body: some View {
        SpriteView(
            scene: myScene,
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
            debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS]
        )
        .background(.black)
        .statusBar(hidden: true)
    }
}

#Preview {
    CameraBasicsView()
}

// MARK: - Scene setup

class CameraBasicsScene: SKScene, UIGestureRecognizerDelegate {
    
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .black
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        setupNavigationCamera(with: view)
        
        setupPinchGesture(in: view)
        setupPangesture(in: view)
        setupRotationGesture(in: view)
        
        createSomeObjects(with: view, random: true, iteration: 1000)
        createPlayPauseUI(with: view, camera: navigationCamera)
        createResetCameraUI(with: view, camera: navigationCamera)
    }
    
    // MARK: - Create objects
    
    let navigationCamera = SKCameraNode()
    let objectsLayer = SKNode()
    
    func setupNavigationCamera(with view: SKView) {
        navigationCamera.name = "camera-main"
        navigationCamera.xScale = (view.bounds.size.width / size.width)
        navigationCamera.yScale = (view.bounds.size.height / size.height)
        scene?.camera = navigationCamera
        navigationCamera.setScale(1)
        
        addChild(navigationCamera)
    }
    
    func createSomeObjects(with view: SKView, random: Bool, iteration: Int) {
        addChild(objectsLayer)
        
        let halfViewWidth = 10000.0
        let halfViewHeight = 20000.0
        
        let gridTexture = SKTexture(imageNamed: "space-1024")
        let spriteTexture = SKTexture(imageNamed: "color-wheel-2")
        
        let label = SKLabelNode(text: "The Reconstruction Project")
        label.name = "label"
        label.preferredMaxLayoutWidth = 300
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.fontName = "Menlo"
        label.fontSize = 32
        label.fontColor = SKColor(white: 1, alpha: 1)
        let labelTexture = view.texture(from: label)
        
        let spinAction = SKAction.rotate(byAngle: .pi * 2, duration: 2)
        
        for _ in 1...iteration {
            let grid = SKSpriteNode(texture: gridTexture)
            grid.alpha = 1
            grid.zPosition = -1
            if random {
                grid.position = CGPoint(
                    x: CGFloat.random(in: -halfViewWidth...halfViewWidth),
                    y: CGFloat.random(in: -halfViewHeight...halfViewHeight)
                )
            }
            
            objectsLayer.addChild(grid)
            
            let sprite = SKSpriteNode(texture: spriteTexture)
            sprite.zPosition = 1
            if random {
                sprite.position = CGPoint(
                    x: CGFloat.random(in: -halfViewWidth...halfViewWidth),
                    y: CGFloat.random(in: -halfViewHeight...halfViewHeight)
                )
            }
            sprite.run(SKAction.repeatForever(spinAction))
            
            objectsLayer.addChild(sprite)
            
            let labelSprite = SKSpriteNode(texture: labelTexture)
            labelSprite.zPosition = 10
            if random {
                labelSprite.position = CGPoint(
                    x: CGFloat.random(in: -halfViewWidth...halfViewWidth),
                    y: CGFloat.random(in: -halfViewHeight...halfViewHeight)
                )
            }
            
            objectsLayer.addChild(labelSprite)
            
            let shape = SKShapeNode(ellipseOf: CGSize(width: 60, height: 30))
            shape.position = CGPoint(x: 0, y: -30)
            shape.zPosition = 2
            shape.lineWidth = 1
            if random {
                shape.position = CGPoint(
                    x: CGFloat.random(in: -halfViewWidth...halfViewWidth),
                    y: CGFloat.random(in: -halfViewHeight...halfViewHeight)
                )
            }
            
            objectsLayer.addChild(shape)
        }
    }
    
    // MARK: - UI
    
    let padding: CGFloat = 20
    
    func createPlayPauseUI(with view: SKView, camera: SKCameraNode) {
        let icon = SKSpriteNode()
        icon.name = "playPause-button-icon"
        icon.texture = isPaused ? SKTexture(imageNamed: "play.fill") : SKTexture(imageNamed: "pause.fill")
        icon.size = CGSize(width: 16, height: 16)
        
        let button = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 30)
        button.name = "playPause-button"
        button.fillColor = SKColor(white: 1, alpha: 0.6)
        button.strokeColor = SKColor(white: 0, alpha: 0.6)
        button.zPosition = 999
        button.position.y = -view.bounds.height / 2 + button.frame.height / 2 + view.safeAreaInsets.bottom + padding
        
        button.addChild(icon)
        camera.addChild(button)
    }
    
    func togglePlayPause(_ touch: UITouch) {
        let touchedNodes = nodes(at: touch.location(in: self))
        
        for node in touchedNodes {
            if node.name == "playPause-button" {
                objectsLayer.isPaused.toggle()
                if let icon = node.childNode(withName: "playPause-button-icon") as? SKSpriteNode {
                    icon.texture = objectsLayer.isPaused ? SKTexture(imageNamed: "play.fill") : SKTexture(imageNamed: "pause.fill")
                }
            }
        }
    }
    
    func createResetCameraUI(with view: SKView, camera: SKCameraNode) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineHeightMultiple = 1
        
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont(name: "GillSans", size: 12) ?? UIFont.systemFont(ofSize: 10),
            .foregroundColor: SKColor(white: 0, alpha: 0.8)
        ]
        
        let label = SKLabelNode()
        label.name = "camera-reset-button-label"
        label.attributedText = NSAttributedString(string: "Reset Camera", attributes: attributes)
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = 44
        label.verticalAlignmentMode = .center
        
        let button = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 30)
        button.name = "camera-reset-button"
        button.fillColor = SKColor(white: 1, alpha: 0.6)
        button.strokeColor = SKColor(white: 0, alpha: 0.6)
        button.zPosition = 999
        button.position.x = -view.bounds.width / 2 + button.frame.width / 2 + view.safeAreaInsets.left + padding
        button.position.y = -view.bounds.height / 2 + button.frame.height / 2 + view.safeAreaInsets.bottom + padding
        
        button.addChild(label)
        camera.addChild(button)
    }
    
    func resetCamera(_ touch: UITouch, camera: SKCameraNode) {
        let touchedNodes = nodes(at: touch.location(in: self))
        for node in touchedNodes {
            if node.name == "camera-reset-button" {
                setCameraTo(camera: camera, scale: 1, position: CGPoint.zero, rotation: 0)
            }
        }
    }
    
    func updateCameraZoomUI(camera: SKCameraNode) {
        /// check if userData dictionary exists
        if camera.userData == nil {
            camera.userData = NSMutableDictionary()
        }

        let scaleInfo = "scaleInfo"
        let zoomLevel = 1 / camera.xScale
        
        /// format based on the zoom level
        let text: String
        if camera.xScale > 1 {
            /// For zooming out, show 2 decimal places
            text = String(format: "%.2f×", zoomLevel)
        } else if camera.xScale == 1 {
            /// For exactly 1, show "1×" without decimals
            text = "1×"
        } else {
            /// For zooming in, show as an integer without decimals
            /// Use rounding to avoid displaying 99.999 as 99×
            let roundedZoomLevel = round(zoomLevel)
            text = String(format: "%.0f×", roundedZoomLevel)
        }
        
        /// try to retrieve an existing label from userData
        if let label = camera.userData?[scaleInfo] as? SKLabelNode {
            label.text = text
        } else {
            /// if not, create one
            let label = SKLabelNode(text: text)
            label.fontName = "GillSans-SemiBold"
            label.fontSize = 16
            label.fontColor = SKColor(white: 0, alpha: 0.8)
            label.position.y = -6
            
            let container = SKShapeNode(rectOf: CGSize(width: 60, height: 32), cornerRadius: 7)
            container.fillColor = SKColor(white: 1, alpha: 0.6)
            container.strokeColor = SKColor(white: 1, alpha: 0.6)
            container.zPosition = 999
            if let view = view {
                container.position = CGPoint(
                    x: -view.bounds.width/2 + view.safeAreaInsets.left + container.frame.size.width/2 + padding,
                    y: view.bounds.height/2 - view.safeAreaInsets.top - container.frame.size.height/2 - padding
                )
            }
            
            container.addChild(label)
            camera.addChild(container)
            
            /// store the newly created label in userData for future access
            camera.userData?[scaleInfo] = label
        }
    }
    
    func updateCameraPositionUI(camera: SKCameraNode) {
        if camera.userData == nil {
            camera.userData = NSMutableDictionary()
        }
        
        let positionInfo = "positionInfo"
        let text = "\(Int(camera.position.x)), \(Int(camera.position.y))"
        
        /// try to retrieve an existing label from userData
        if let label = camera.userData?[positionInfo] as? SKLabelNode {
            label.text = text
            label.position.x = -label.frame.width / 2
        } else {
            /// if not, create one
            let label = SKLabelNode(text: text)
            label.fontName = "GillSans-SemiBold"
            label.fontSize = 16
            label.fontColor = SKColor(white: 0, alpha: 0.8)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .left
            
            let container = SKShapeNode(rectOf: CGSize(width: 160, height: 32), cornerRadius: 7)
            container.fillColor = SKColor(white: 1, alpha: 0.6)
            container.strokeColor = SKColor(white: 1, alpha: 0.6)
            container.zPosition = 999
            if let view = view {
                container.position = CGPoint(
                    x: -view.bounds.width/2 + view.safeAreaInsets.left + container.frame.size.width/2 + padding,
                    y: view.bounds.height/2 - view.safeAreaInsets.top - container.frame.size.height/2 - padding - 40
                )
            }
            
            container.addChild(label)
            camera.addChild(container)
            
            /// store the newly created label in userData for future access
            camera.userData?[positionInfo] = label
        }
    }
    
    // MARK: - Filtering mode
    
    var wasCameraScaleBelowOne: Bool? = nil
    
    func updateFilteringModeBasedOnCameraScale(cameraScale: CGFloat) {
        let isCameraScaleBelowOne = cameraScale < 1
        
        /// Check if the scale state has changed (crossed the threshold of 1)
        if wasCameraScaleBelowOne == nil || wasCameraScaleBelowOne != isCameraScaleBelowOne {
            /// apply pixelated rendering for sprite textures when the camera is zoomed in
            let filteringMode: SKTextureFilteringMode = isCameraScaleBelowOne ? .nearest : .linear
            /// disable antialiasing for shape nodes when camera is zommed in
            let shouldAntialias = !isCameraScaleBelowOne
            
            enumerateChildNodes(withName: "//*") { node, _ in
                if let spriteNode = node as? SKSpriteNode {
                    spriteNode.texture?.filteringMode = filteringMode
                } else if let shapeNode = node as? SKShapeNode {
                    shapeNode.isAntialiased = shouldAntialias
                }
            }
            
            wasCameraScaleBelowOne = isCameraScaleBelowOne
        }
    }
    
    // MARK: - Camera zoom
    
    /// store current pinching strength
    var cameraScaleVelocity: CGFloat = 0
    
    /// lower values = more friction
    var cameraScaleFriction: CGFloat = 0.95
    
    /// max and min zoom levels
    var cameraMaxScale: CGFloat = 100
    var cameraMinScale: CGFloat = 0.01
    
    func scaleCamera(camera: SKCameraNode, gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            /// calculate the new scale, and clamp within the range
            let newScale = camera.xScale / gesture.scale
            let clampedScale = max(min(newScale, cameraMaxScale), cameraMinScale)
            
            /// calculate a factor to move the camera toward the pinch midpoint
            let translateFactor = clampedScale / camera.xScale
            
            /// calculate the new camera position
            let pinchMidpointInView = gesture.location(in: view)
            let pinchLocationInScene = convertPoint(fromView: pinchMidpointInView)
            let newCamPosX = pinchLocationInScene.x + (camera.position.x - pinchLocationInScene.x) * translateFactor
            let newCamPosY = pinchLocationInScene.y + (camera.position.y - pinchLocationInScene.y) * translateFactor
            
            /// update camera's scale and position
            camera.setScale(clampedScale)
            camera.position = CGPoint(x: newCamPosX, y: newCamPosY)
            
            /// reset scale to 1.0 after adjusting the camera scale to ensure smooth and continuous scaling
            gesture.scale = 1.0
            
            /// update texture filtering mode based on camera scale
            updateFilteringModeBasedOnCameraScale(cameraScale: camera.xScale)
        }
        if (gesture.state == .ended) {
            cameraScaleVelocity = camera.xScale * gesture.velocity / 100
        }
    }
    
    func updateCameraScaleVelocity(camera: SKCameraNode) {
        /// this function is called by the update loop each frame
        /// reduce the load by checking the current scale velocity first
        if (cameraScaleVelocity != 0) {
            /// x and y should always be scaling equally,
            /// but just in case something happens to throw them out of whack... set them equal
            camera.yScale = camera.xScale
            
            /// Apply friction to velocity so the camera slows to a stop when user interaction ends.
            cameraScaleVelocity *= cameraScaleFriction
            
            /// Stop the camera when velocity has approached close enough to zero
            if (abs(cameraScaleVelocity) < 0.001) {
                cameraScaleVelocity = 0
            }
            
            let newScale = camera.xScale - cameraScaleVelocity
            
            /// prevent the inertial zooming from exceeding the zoom limits
            let clampedScale = max(min(newScale, cameraMaxScale), cameraMinScale)
            camera.setScale(clampedScale)
            
            /// update texture filtering mode based on camera scale
            updateFilteringModeBasedOnCameraScale(cameraScale: camera.xScale)
        }
    }
    
    func stopCameraScale() {
        /// this function is called by the touchBegan function
        /// stop any ongoing inertial zooming
        cameraScaleVelocity = 0
    }

    // MARK: - Camera pan
    
    /// store camera velocity
    var cameraPositionVelocity: (x: CGFloat, y: CGFloat) = (0, 0)
    /// camera inertia friction. Lower values = more friction
    var cameraPositionFriction: CGFloat = 0.95
    
    func stopCameraPan() {
        /// this function is called by the touchBegan function
        /// stop any ongoing inertial movement
        if (cameraPositionVelocity.x != 0 || cameraPositionVelocity.y != 0) {
            cameraPositionVelocity = (0.0, 0.0)
        }
    }
    
    func panCamera(camera: SKCameraNode, gesture: UIPanGestureRecognizer) {
        /// this function is called by the pan gesture recognizer
        /// while user interaction is happening simply apply thier changes directly to the camera
        /// translation must be multiplied by scale to keep a consistent pan at all zoom levels
        let translation = gesture.translation(in: self.view)
        
        
        /// Convert translation to account for camera rotation
        let angle = -camera.zRotation // Use negative angle because SK rotation is clockwise
        let dx = translation.x * cos(angle) - translation.y * sin(angle)
        let dy = translation.x * sin(angle) + translation.y * cos(angle)
        
        /// Apply adjusted translation to camera position
        /// Multiply by camera.scale to adjust for zoom level
        camera.position = CGPoint(x: camera.position.x - dx * camera.xScale,
                                  y: camera.position.y + dy * camera.yScale)
        
        /// reset the translation so that next cycle we get the delta from our new position
        gesture.setTranslation(CGPoint.zero, in: self.view)
        
        /// once user interaction ends, we get the gesture velocity and set up the inertial camera slide
        /// we multiply the velocity by scale so that panning appears to happen at the same rate at every zoom level
        /// recognizer velocity is reduced to provide a more pleasant user experience.
        if (gesture.state == .ended) {
            let panVelocity = (gesture.velocity(in: self.view))
            cameraPositionVelocity.x = camera.xScale * panVelocity.x / 100
            cameraPositionVelocity.y = camera.yScale * panVelocity.y / 100
        }
    }
    
    func updateCameraPositionVelocity(camera: SKCameraNode) {
        /// this function is called by the update loop each frame
        if (cameraPositionVelocity.x != 0 || cameraPositionVelocity.y != 0) {
            /// apply friction to x velocity so the camera can slow to a stop
            cameraPositionVelocity.x *= cameraPositionFriction
            
            /// since friction is typically a value like 0.95 it will mathematically never reach zero,
            /// so we need to set a minimum velocity where we can assume the camera has basically stopped moving.
            if (abs(cameraPositionVelocity.x) < 0.01) {
                cameraPositionVelocity.x = 0
            }
            
            /// apply friction to the y velocity so the camera can slow to a stop
            cameraPositionVelocity.y *= cameraPositionFriction
            
            /// Stop the camera when velocity has approached close enough to zero
            if (abs(cameraPositionVelocity.y) < 0.01) {
                cameraPositionVelocity.y = 0
            }
            
            camera.position.x -= cameraPositionVelocity.x
            camera.position.y += cameraPositionVelocity.y
        }
    }
    
    // MARK: - Camera rotation
    
    var cameraRotation: CGFloat = 0
    var cameraRotationVelocity: CGFloat = 0
    var cameraRotationFriction: CGFloat = 0.85
    
    func rotateCamera(camera: SKCameraNode, gesture: UIRotationGestureRecognizer) {
        if gesture.state == .began {
            /// Store the current camera rotation when the gesture begins
            cameraRotation = camera.zRotation
        }
        if gesture.state == .changed {
            /// Calculate the new rotation by adding the gesture rotation to the initial camera rotation
            let newRotation = cameraRotation + gesture.rotation
            
            /// Apply the new rotation to the camera
            camera.zRotation = newRotation
        }
        if gesture.state == .ended {
            cameraRotationVelocity = camera.zRotation * gesture.velocity / 100
        }
    }
    
    func updateCameraRotationVelocity(camera: SKCameraNode) {
        /// this function is called by the update loop each frame
        /// reduce the load by checking the current scale velocity first
        if (cameraRotationVelocity != 0) {
            
            /// Apply friction to velocity so the camera slows to a stop when user interaction ends.
            cameraRotationVelocity *= cameraRotationFriction
            
            /// Stop the camera when velocity has approached close enough to zero
            if (abs(cameraRotationVelocity) < 0.01) {
                cameraRotationVelocity = 0
            }
            
            let newRotation = camera.zRotation - cameraRotationVelocity
            camera.zRotation = newRotation
        }
    }
    
    // MARK: - Set camera
    
    func setCameraTo(camera: SKCameraNode, scale: CGFloat, position: CGPoint, rotation: CGFloat) {
        let resetDuration = durationForZoomReset(from: camera.xScale, to: scale)
        
        let scaleAction = SKAction.scale(to: scale, duration: resetDuration)
        let moveAction = SKAction.move(to: position, duration: resetDuration)
        let rotationAction = SKAction.rotate(toAngle: rotation, duration: resetDuration)
        scaleAction.timingMode = .easeOut
        moveAction.timingMode = .easeOut
        rotationAction.timingMode = .easeOut
        let groupAction = SKAction.group([scaleAction, moveAction, rotationAction])
        camera.run(groupAction)
    }
    
    func durationForZoomReset(from currentScale: CGFloat, to targetScale: CGFloat) -> TimeInterval {
        let scaleDifference = abs(currentScale - targetScale)
        let maxDuration: TimeInterval = 0.5
        let duration = TimeInterval(scaleDifference) * maxDuration
        return max(0.1, min(duration, maxDuration))
    }
    
    // MARK: - Update loop
    
    override func update(_ currentTime: TimeInterval) {
        updateCameraPositionVelocity(camera: navigationCamera)
        updateCameraScaleVelocity(camera: navigationCamera)
        updateCameraRotationVelocity(camera: navigationCamera)
        
        updateCameraZoomUI(camera: navigationCamera)
        updateCameraPositionUI(camera: navigationCamera)
    }
    
    // MARK: - Gesture recognizers
    
    /// allow multiple gesture recognizers to recognize gestures at the same time
    /// for this function to work, the protocol `UIGestureRecognizerDelegate` must be added to this class
    /// and a delegate must be set on the recognizer that needs to work with others
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /// Use this function to determine if the gesture recognizer should handle the touch
    /// For example, return false if the touch is within a certain area that should only respond to direct touch events
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    /// pan gesture
    func setupPangesture(in view: SKView) {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer.delegate = self
        /// this prevents the recognizer from cancelling basic touch events once a gesture is recognized
        /// In UIKit, this property is set to true by default
        panGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        panCamera(camera: navigationCamera, gesture: gesture)
    }
    
    /// pinch gesture
    func setupPinchGesture(in view: SKView) {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        pinchGesture.delegate = self
        pinchGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(pinchGesture)
    }
    
    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        scaleCamera(camera: navigationCamera, gesture: gesture)
    }
    
    /// rotation gesture
    func setupRotationGesture(in view: SKView) {
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture(_:)))
        rotationGesture.delegate = self
        rotationGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(rotationGesture)
    }
    
    @objc func handleRotationGesture(_ gesture: UIRotationGestureRecognizer) {
        rotateCamera(camera: navigationCamera, gesture: gesture)
    }
    
    // MARK: - Touch visualization
    
    var touchPoints = [UITouch: SKShapeNode]()

    func createTouchPoint(touch: UITouch, camera: SKCameraNode) -> SKShapeNode {
        let position = touch.location(in: self)
        let convertedPosition = camera.convert(position, from: self)
        let touchRadius = touch.majorRadius
        
        let touchPoint = SKShapeNode(circleOfRadius: touchRadius)
        touchPoint.position = convertedPosition
        touchPoint.fillColor = SKColor.red.withAlphaComponent(0.5)
        touchPoint.strokeColor = SKColor(white: 1, alpha: 0.6)
        touchPoint.zPosition = 999
        
        return touchPoint
    }
    
    func visualizeTouchBegan(touch: UITouch, camera: SKCameraNode) {
        let touchPoint = createTouchPoint(touch: touch, camera: camera)
        touchPoints[touch] = touchPoint
        camera.addChild(touchPoint)
    }
    
    func visualizeTouchMoved(touch: UITouch, camera: SKCameraNode) {
        if let touchPoint = touchPoints[touch] {
            let newPosition = touch.location(in: self)
            touchPoint.position = camera.convert(newPosition, from: self)
        }
    }
    
    func visualizeTouchEnded(touch: UITouch) {
        touchPoints[touch]?.removeFromParent()
        touchPoints[touch] = nil
    }
    
    // MARK: - Touch events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            stopCameraPan()
            stopCameraScale()
            togglePlayPause(touch)
            visualizeTouchBegan(touch: touch, camera: navigationCamera)
            resetCamera(touch, camera: navigationCamera)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            visualizeTouchMoved(touch: touch, camera: navigationCamera)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            visualizeTouchEnded(touch: touch)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}

