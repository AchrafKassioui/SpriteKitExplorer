/**
 
 # SpriteKit Inertial Camera - Draft 01
 
 Achraf Kassioui
 Created: 30 March 2024
 Updated: 1 April 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - Live preview

struct InertialCameraView01: View {
    var myScene = InertialCamera01Scene()
    
    var body: some View {
        SpriteView(
            scene: myScene,
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
            debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS]
        )
        .background(.gray)
    }
}

#Preview {
    InertialCameraView01()
}

// MARK: - Scene setup

class InertialCamera01Scene: SKScene, UIGestureRecognizerDelegate {
    
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .systemGray
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        setupNavigationCamera(with: view)
        
        setupGestureRecognizers(in: view)
        
        createSomeObjects(with: view, random: true, iteration: 2000)
        createPlayPauseUI(with: view, camera: navigationCamera)
        createResetCameraUI(with: view, camera: navigationCamera)
        createActionButton(in: view)
    }
    
    // MARK: - Create objects
    
    let navigationCamera = SKCameraNode()
    let objectsLayer = SKNode()
    let uiLayer = SKNode()
    
    func setupNavigationCamera(with view: SKView) {
        navigationCamera.name = "camera-main"
        navigationCamera.xScale = (view.bounds.size.width / size.width)
        navigationCamera.yScale = (view.bounds.size.height / size.height)
        scene?.camera = navigationCamera
        navigationCamera.setScale(1)
        
        navigationCamera.addChild(uiLayer)
        addChild(navigationCamera)
    }
    
    /// Populate the scene with objects
    /// - parameters:
    ///     - parameter view: pass the view to avoid optionals. View methods are used to generate textures from label and shape nodes
    ///     - parameter random: whether the objects are posiyioned randomly or not
    ///     - parameter iteration: how many times the predefined objects should be duplicated
    func createSomeObjects(with view: SKView, random: Bool, iteration: Int) {
        addChild(objectsLayer)
        
        /// an arbitrary size for the scene
        let halfViewWidth = 20000.0
        let halfViewHeight = 40000.0
        
        let gridTexture = SKTexture(imageNamed: "grid-60-6x12-white")
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
    
    /// UI settings
    let myPadding: CGFloat = 20
    let myFontName: String = "GillSans-SemiBold"
    let myFontColor = SKColor(white: 0, alpha: 0.8)
    let myFillColor = SKColor(white: 1, alpha: 0.9)
    let myStrokeColor = SKColor(white: 0, alpha: 0.6)
    let myBlendMode: SKBlendMode = .replace
    
    func createPlayPauseUI(with view: SKView, camera: SKCameraNode) {
        let icon = SKSpriteNode()
        icon.name = "playPause-button-icon"
        icon.texture = isPaused ? SKTexture(imageNamed: "play.fill.white") : SKTexture(imageNamed: "pause.fill.white")
        icon.size = CGSize(width: 16, height: 16)
        icon.colorBlendFactor = 1
        icon.color = SKColor(white: 0, alpha: 1)
        
        let button = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 30)
        button.name = "playPause-button"
        button.fillColor = myFillColor
        button.strokeColor = myStrokeColor
        button.blendMode = myBlendMode
        button.zPosition = 999
        button.position.y = -view.bounds.height / 2 + button.frame.height / 2 + view.safeAreaInsets.bottom + myPadding
        
        button.addChild(icon)
        uiLayer.addChild(button)
    }
    
    func togglePlayPause() {
        objectsLayer.isPaused.toggle()
        if let icon = childNode(withName: "//playPause-button-icon") as? SKSpriteNode {
            icon.texture = objectsLayer.isPaused ? SKTexture(imageNamed: "play.fill.white") : SKTexture(imageNamed: "pause.fill.white")
        }
    }
    
    func createResetCameraUI(with view: SKView, camera: SKCameraNode) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineHeightMultiple = 1
        
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont(name: myFontName, size: 12) ?? UIFont.systemFont(ofSize: 10),
            .foregroundColor: myFontColor
        ]
        
        let label = SKLabelNode()
        label.name = "camera-reset-button-label"
        label.attributedText = NSAttributedString(string: "Reset Camera", attributes: attributes)
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = 44
        label.verticalAlignmentMode = .center
        
        let button = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 30)
        button.name = "camera-reset-button"
        button.fillColor = myFillColor
        button.strokeColor = myStrokeColor
        button.blendMode = myBlendMode
        button.zPosition = 999
        button.position.x = -view.bounds.width / 2 + button.frame.width / 2 + view.safeAreaInsets.left + myPadding
        button.position.y = -view.bounds.height / 2 + button.frame.height / 2 + view.safeAreaInsets.bottom + myPadding
        
        button.addChild(label)
        uiLayer.addChild(button)
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
            label.fontName = myFontName
            label.fontSize = 16
            label.fontColor = myFontColor
            label.position.y = -6
            
            let container = SKShapeNode(rectOf: CGSize(width: 60, height: 32), cornerRadius: 7)
            container.fillColor = myFillColor
            container.strokeColor = myStrokeColor
            container.blendMode = myBlendMode
            container.zPosition = 999
            if let view = view {
                container.position = CGPoint(
                    x: -view.bounds.width/2 + view.safeAreaInsets.left + container.frame.size.width/2 + myPadding,
                    y: view.bounds.height/2 - view.safeAreaInsets.top - container.frame.size.height/2 - myPadding
                )
            }
            
            container.addChild(label)
            uiLayer.addChild(container)
            
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
            label.fontName = myFontName
            label.fontSize = 16
            label.fontColor = myFontColor
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .left
            
            let container = SKShapeNode(rectOf: CGSize(width: 160, height: 32), cornerRadius: 7)
            container.fillColor = myFillColor
            container.strokeColor = myStrokeColor
            container.blendMode = myBlendMode
            container.zPosition = 999
            if let view = view {
                container.position = CGPoint(
                    x: -view.bounds.width/2 + view.safeAreaInsets.left + container.frame.size.width/2 + myPadding,
                    y: view.bounds.height/2 - view.safeAreaInsets.top - container.frame.size.height/2 - myPadding - 40
                )
            }
            
            container.addChild(label)
            uiLayer.addChild(container)
            
            /// store the newly created label in userData for future access
            camera.userData?[positionInfo] = label
        }
    }
    
    /// a button used for arbitrary functions
    func createActionButton(in view: SKView) {
        let label = SKLabelNode(text: "A")
        label.fontName = "myFontName"
        label.fontColor = myFontColor
        label.fontSize = 24
        label.name = "button-action-label"
        label.verticalAlignmentMode = .center
        
        let button = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 30)
        button.name = "button-action"
        button.fillColor = myFillColor
        button.strokeColor = myStrokeColor
        button.blendMode = myBlendMode
        button.zPosition = 999
        button.position.x = view.bounds.width / 2 - button.frame.width / 2 - myPadding
        button.position.y = -view.bounds.height / 2 + button.frame.height / 2 + view.safeAreaInsets.bottom + myPadding
        
        button.addChild(label)
        uiLayer.addChild(button)
    }
    
    // MARK: - Filtering mode
    /**
     
     We change the filtering mode of the renderer depending on camera scale.
     When the scale is below 1 (zoom in), we disable linear filtering and anti aliasing.
     When the scale is 1 or above (zoom out), we enable linear filtering and anti aliasing.
     
     */
    var wasCameraScaleBelowOne: Bool? = nil
    
    func updateFilteringModeBasedOnCameraScale(cameraScale: CGFloat) {
        let isCameraScaleBelowOne = cameraScale < 1
        
        /// Check if the scale state has changed (crossed the threshold of 1)
        if wasCameraScaleBelowOne == nil || wasCameraScaleBelowOne != isCameraScaleBelowOne {
            /// apply pixelated rendering for sprite textures when the camera is zoomed in
            let filteringMode: SKTextureFilteringMode = isCameraScaleBelowOne ? .nearest : .linear
            /// disable antialiasing for shape nodes when camera is zommed in
            let shouldAntialias = !isCameraScaleBelowOne
            
            /// there is probably a more performant way to implement this logic
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
    
    /// this function is called to stop any ongoing inertia
    func stopCamera() {
        cameraScaleVelocity = 0
        cameraPositionVelocity = (0.0, 0.0)
        cameraRotationVelocity = 0
    }
    
    // MARK: - Update loop
    
    override func update(_ currentTime: TimeInterval) {
        updateCameraPositionVelocity(camera: navigationCamera)
        updateCameraScaleVelocity(camera: navigationCamera)
        updateCameraRotationVelocity(camera: navigationCamera)
        
        updateCameraZoomUI(camera: navigationCamera)
        updateCameraPositionUI(camera: navigationCamera)
    }
    
    // MARK: - Camera zoom
    
    /// zoom settings
    var cameraMaxScale: CGFloat = 100
    var cameraMinScale: CGFloat = 0.01
    var cameraScaleFriction: CGFloat = 0.75 /// lower values = more friction
    
    /// zoom state
    var cameraScaleVelocity: CGFloat = 0
    var cameraScaleWhenGestureStarts: CGFloat = 1
    var scaleCenterWhenGestureStarts = CGPoint.zero
    
    func scaleCamera(camera: SKCameraNode, gesture: UIPinchGestureRecognizer) {
        let scaleCenterInView = gesture.location(in: view)
        let scaleCenterInScene = convertPoint(fromView: scaleCenterInView)
        
        if gesture.state == .began {
            cameraScaleWhenGestureStarts = camera.xScale
            scaleCenterWhenGestureStarts = scaleCenterInScene
        }
        
        if gesture.state == .changed {
            /// calculate the new scale, and clamp within the range
            let newScale = camera.xScale / gesture.scale
            let clampedScale = max(min(newScale, cameraMaxScale), cameraMinScale)
            
            /// calculate a factor to move the camera toward the pinch midpoint
            let translationFactor = clampedScale / camera.xScale
            let newCamPosX = scaleCenterInScene.x + (camera.position.x - scaleCenterInScene.x) * translationFactor
            let newCamPosY = scaleCenterInScene.y + (camera.position.y - scaleCenterInScene.y) * translationFactor
            
            /// update camera's scale and position
            camera.setScale(clampedScale)
            camera.position = CGPoint(x: newCamPosX, y: newCamPosY)
            
            gesture.scale = 1.0
        }
        
        if gesture.state == .ended {
            cameraScaleVelocity = camera.xScale * gesture.velocity / 100
        }
        
        if gesture.state == .cancelled {
            camera.setScale(cameraScaleWhenGestureStarts)
        }
    }
    
    /// this function is called by the update loop each frame
    func updateCameraScaleVelocity(camera: SKCameraNode) {
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
    
    // MARK: - Camera pan
    
    /// pan settings
    var cameraPositionFriction: CGFloat = 0.95 /// lower values = more friction
    
    /// pan state
    var cameraPositionVelocity: (x: CGFloat, y: CGFloat) = (0, 0)
    var cameraPositionWhenGestureStarts = CGPoint.zero
    var cameraPositionTranslation = CGPoint.zero
    
    func panCamera(camera: SKCameraNode, gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            cameraPositionWhenGestureStarts = camera.position
            cameraPositionTranslation = gesture.translation(in: self.view)
        }
        
        if gesture.state == .changed {
            let translation = gesture.translation(in: self.view)
            /// store ongoing translation to use in case of a simultaneous rotation
            
            /// Calculate adjusted translation based on the current rotation
            let angle = -camera.zRotation
            let dx = translation.x * cos(angle) - translation.y * sin(angle)
            let dy = translation.x * sin(angle) + translation.y * cos(angle)
            
            /// Apply adjusted translation to camera position
            camera.position = CGPoint(x: cameraPositionWhenGestureStarts.x - dx * camera.xScale,
                                      y: cameraPositionWhenGestureStarts.y + dy * camera.yScale)
            
            cameraPositionTranslation = translation * camera.yScale
        }
        
        if gesture.state == .ended {
            /// get the velocity, adjust for zoom level, and divide by an arbitrary factor for better user experience
            cameraPositionVelocity.x = camera.xScale * gesture.velocity(in: self.view).x / 100
            cameraPositionVelocity.y = camera.yScale * gesture.velocity(in: self.view).y / 100
        }
        
        if gesture.state == .cancelled {
            camera.position = cameraPositionWhenGestureStarts
        }
    }
    
    /// this function is called by the update loop each frame
    func updateCameraPositionVelocity(camera: SKCameraNode) {
        if (cameraPositionVelocity.x != 0 || cameraPositionVelocity.y != 0) {
            /// apply friction to velocity
            cameraPositionVelocity.x *= cameraPositionFriction
            cameraPositionVelocity.y *= cameraPositionFriction
            
            /// calculate the rotated velocity to account for camera rotation
            let angle = camera.zRotation
            let rotatedVelocityX = cameraPositionVelocity.x * cos(angle) + cameraPositionVelocity.y * sin(angle)
            let rotatedVelocityY = -cameraPositionVelocity.x * sin(angle) + cameraPositionVelocity.y * cos(angle)
            
            /// Stop the camera when velocity is near zero to prevent oscillation
            if abs(cameraPositionVelocity.x) < 0.01 { cameraPositionVelocity.x = 0 }
            if abs(cameraPositionVelocity.y) < 0.01 { cameraPositionVelocity.y = 0 }
            
            /// Update the camera's position with the rotated velocity
            camera.position.x -= rotatedVelocityX
            camera.position.y += rotatedVelocityY
        }
    }
    
    // MARK: - Camera rotation
    
    /// rotation settings
    var cameraRotationFriction: CGFloat = 0.75 /// lower values = more friction
    
    /// rotation state
    var cameraRotationVelocity: CGFloat = 0
    var cameraRotationWhenGestureStarts: CGFloat = 0
    var rotationCenterWhenGestureStarts = CGPoint.zero
    
    func rotateCamera(camera: SKCameraNode, gesture: UIRotationGestureRecognizer) {
        let rotationCenterInView = gesture.location(in: view)
        let rotationCenterInScene = convertPoint(fromView: rotationCenterInView)
        
        if gesture.state == .began {
            cameraPositionWhenGestureStarts = camera.position
            cameraRotationWhenGestureStarts = camera.zRotation
            rotationCenterWhenGestureStarts = rotationCenterInScene
        }
        
        if gesture.state == .changed {
            /// Calculate the change in rotation since the gesture began
            let newRotation = gesture.rotation
            
            /// Rotate the offset from the center of rotation
            let dx = (cameraPositionWhenGestureStarts.x - rotationCenterWhenGestureStarts.x - cameraPositionTranslation.x) * camera.xScale
            let dy = -(cameraPositionWhenGestureStarts.y - rotationCenterWhenGestureStarts.y - cameraPositionTranslation.y) * camera.yScale
            
            let distanceToCenter = sqrt(dx * dx + dy * dy)
            
            /// New angle considering rotation
            let angleToCenter = atan2(dy, dx) + newRotation
            
            /// Apply scale to distance for consistent rotation at any zoom level
            let scaledDistanceToCenter = distanceToCenter / camera.xScale
            
            /// Calculate the new camera position
            let newCameraX = rotationCenterWhenGestureStarts.x + scaledDistanceToCenter * cos(angleToCenter)
            let newCameraY = rotationCenterWhenGestureStarts.y + scaledDistanceToCenter * sin(angleToCenter)
            camera.position = CGPoint(x: newCameraX,y: newCameraY)
            
            /// Apply the new rotation to the camera
            camera.zRotation = cameraRotationWhenGestureStarts + newRotation
        }
        
        if gesture.state == .ended {
            cameraRotationVelocity = camera.xScale * gesture.velocity / 100
        }
        
        if gesture.state == .cancelled {
            camera.zRotation = cameraRotationWhenGestureStarts
            //camera.position = cameraPositionWhenGestureStarts
        }
    }
    
    /// this function is called by the update loop each frame
    func updateCameraRotationVelocity(camera: SKCameraNode) {
        /// reduce the load by checking the current scale velocity first
        if (cameraRotationVelocity != 0) {
            /// Apply friction to velocity so the camera slows to a stop when user interaction ends
            cameraRotationVelocity *= cameraRotationFriction
            
            /// Stop the camera when velocity has approached close enough to zero
            if (abs(cameraRotationVelocity) < 0.01) {
                cameraRotationVelocity = 0
            }
            
            camera.zRotation += cameraRotationVelocity
        }
    }
    
    // MARK: - Gesture recognizers
    
    func setupGestureRecognizers(in view: SKView) {
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        let rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture(_:)))
        
        pinchRecognizer.delegate = self
        panRecognizer.delegate = self
        rotationRecognizer.delegate = self
        
        /// this prevents the recognizer from cancelling basic touch events once a gesture is recognized
        /// In UIKit, this property is set to true by default
        pinchRecognizer.cancelsTouchesInView = false
        panRecognizer.cancelsTouchesInView = false
        rotationRecognizer.cancelsTouchesInView = false
        
        view.addGestureRecognizer(pinchRecognizer)
        view.addGestureRecognizer(panRecognizer)
        view.addGestureRecognizer(rotationRecognizer)
    }
    
    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        scaleCamera(camera: navigationCamera, gesture: gesture)
    }
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        panCamera(camera: navigationCamera, gesture: gesture)
    }
    
    @objc func handleRotationGesture(_ gesture: UIRotationGestureRecognizer) {
        rotateCamera(camera: navigationCamera, gesture: gesture)
    }
    
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
    
    // MARK: - Touch visualization
    
    var touchPoints = [UITouch: SKShapeNode]()
    
    func createTouchPoint(touch: UITouch, camera: SKCameraNode) -> SKShapeNode {
        let position = touch.location(in: self)
        let convertedPosition = camera.convert(position, from: self)
        
        let touchPoint = SKShapeNode(circleOfRadius: 22)
        touchPoint.position = convertedPosition
        touchPoint.fillColor = SKColor.systemBlue.withAlphaComponent(0.5)
        touchPoint.strokeColor = SKColor(white: 1, alpha: 0.9)
        touchPoint.zPosition = 9999
        
        return touchPoint
    }
    
    func visualizeTouchBegan(touch: UITouch, camera: SKCameraNode) {
        let touchPoint = createTouchPoint(touch: touch, camera: camera)
        touchPoint.name = "touchPoint"
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
            let foremostNode = atPoint(touch.location(in: self))
            
            if foremostNode.name != "button-action" && foremostNode.name != "button-action-label" {
                stopCamera()
            } else {
                cameraPositionVelocity.y -= 5
            }
            
            if foremostNode.name == "playPause-button" || foremostNode.name == "playPause-button-icon" {
                togglePlayPause()
            }
            
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

