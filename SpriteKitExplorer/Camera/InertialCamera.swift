/**
 
 # SpriteKit Inertial Camera
 
 This is a subclass of SpriteKit SKCameraNode that allow you to navigate around the scene as if it were an infinite canvas (which a SpriteKit scene is).
 You use pan, pinch, and rotate gestures to control the camera.
 The camera also implement inertia: at the end of a gesture, the velocity is maintained then slowed down progressively.
 
 Made for iOS. Not adpated for macOS yet.
 
 ## Setup
 
 ```
 override func didMove(to view: SKView) {
    size = view.bounds.size
    let myCamera = InertialCameraNode(view: view, scene: self)
    camera = myCamera
    addChild(myCamera)
 }
 
 ```
 
 ## Inertia
 
 You can enable inertial panning, zooming, and rotating by calling the `updateInertia` method inside the SKScene update loop.
 
 ```
 override func update(_ currentTime: TimeInterval) {
    if let myCamera = camera as? InertialCamera {
        myCamera.updateInertia()
    }
 }
 ```
 
 You can also selectively toggle inertia on each of pan, pinch, and rotate in the camera settings inside the class.
 
 ## Texture filtering
 
 This camera is set up so it changes the filtering mode of SKSpriteNode and SKShapeNode depending on zoom level.
 The default SpriteKit smoothing is applied at 1:1 scale and when the camera is zoomed out.
 Smoothing is disabled when the camera is zoomed in (magnification), to see the pixel grid.
 This mimicks what bitmap graphical authoring tools do.
 
 
 ## Challenges
 
 Implementing simulataneous pan and rotation has been a challenge. See: https://gist.github.com/AchrafKassioui/bd835b99a78e9ce29b08ce406896c59b
 
 
 Achraf Kassioui
 Created: 8 April 2024
 Updated: 8 April 2024
 
 */

import SpriteKit

class InertialCamera: SKCameraNode, UIGestureRecognizerDelegate {
    
    // MARK: - Settings
    
    /// toggle inertia
    var enablePanInertia = true
    var enableScaleInertia = true
    var enableRotationInertia = true
    
    /// inertia (friction) settings
    var cameraPositionInertia: CGFloat = 0.95
    var cameraScaleInertia: CGFloat = 0.75
    var cameraRotationInertia: CGFloat = 0.85
    
    /// zoom settings
    var cameraMaxScale: CGFloat = 100 /// a max zoom out of 0.01x
    var cameraMinScale: CGFloat = 0.01 /// a max zoom in of 100x
    
    /// adaptive filtering
    var adaptiveFiltering = true
    
    /// toggle gesture recognition
    var lock = false
    
    // MARK: - Initialization
    /**
     
     We need some methods from the `view` and `scene` objects. We pass them as weak references when we instantiate the camera.
     We setup the gesture recognizers on the view.
     
     */
    
    weak private var theView: SKView?
    weak private var theScene: SKScene?
    
    init(view: SKView, scene: SKScene) {
        self.theView = view
        self.theScene = scene
        
        super.init()
        
        self.setupGestureRecognizers(in: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Set camera
    /**
     
     Set the camera to a specific position, scale, and rotation.
     
     */
    // TODO: add animation
    
    func setCameraTo(position: CGPoint, xScale: CGFloat, yScale: CGFloat, rotation: CGFloat) {
        self.position = position
        self.xScale = xScale
        self.yScale = yScale
        self.zRotation = rotation
    }
    
    // MARK: - Filtering mode
    /**
     
     We change the filtering mode of the renderer depending on camera scale.
     When the scale is below 1 (zoom in) for either x or y, we disable linear filtering and anti aliasing.
     When the scale is 1 or above (zoom out) for either x and y, we enable linear filtering and anti aliasing.
     This function is called whenever the camera scale is changed, using the property observer `didSet`
     
     */
    
    private var _wasCameraScaleBelowOne: (x: Bool, y: Bool) = (false, false)
    
    override var xScale: CGFloat {
        didSet { updateFilteringMode() }
    }
    
    override var yScale: CGFloat {
        didSet { updateFilteringMode() }
    }
    
    private func updateFilteringMode() {
        /// Check both scales
        let isCameraScaleBelowOne = xScale < 1 || yScale < 1
        
        /// Check if the scale state has changed (crossed the threshold of 1)
        if adaptiveFiltering && (_wasCameraScaleBelowOne.x != isCameraScaleBelowOne || _wasCameraScaleBelowOne.y != isCameraScaleBelowOne) {
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
            
            _wasCameraScaleBelowOne = (xScale < 1, yScale < 1)
        }
    }
    
    // MARK: - Pan
    
    /// pan state
    private var cameraPositionBeforePan = CGPoint.zero
    private var cameraPositionVelocity: (x: CGFloat, y: CGFloat) = (0, 0)
    
    @objc private func panCamera(gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            
            /// store the camera's position at the beginning of the pan gesture
            cameraPositionBeforePan = self.position
            
        } else if gesture.state == .changed {
            
            /// convert UIKit translation coordinates to SpriteKit's coordinates for mathematical clarity further down
            let uiKitTranslation = gesture.translation(in: theView)
            let translation = CGPoint(
                /// UIKit and SpriteKit share the same x-axis direction
                x: uiKitTranslation.x,
                /// invert y because UIKit's y-axis increases downwards, opposite to SpriteKit's
                y: -uiKitTranslation.y
            )
            
            /// transform the translation from the screen coordinate system to the camera's local coordinate system, considering its rotation.
            let angle = self.zRotation
            let dx = translation.x * cos(angle) - translation.y * sin(angle)
            let dy = translation.x * sin(angle) + translation.y * cos(angle)
            
            /// apply the transformed translation to the camera's position, accounting for the current scale.
            /// we moves the camera opposite to the gesture direction (-dx and -dy), building the impression of moving the scene itself.
            /// if we wanted direct manipulation of a node, dx and dy would be added instead of subtracted.
            self.position = CGPoint(
                x: self.position.x - dx * self.xScale,
                y: self.position.y - dy * self.yScale
            )
            
            /// it is important to use a logic that applies position modifications to the current camera position, then reset the translation delta each time
            /// this way, panning and rotation, which both change the camera position, can work together
            /// a logic where we use a cumulative translation since the gesture has began would mess up the position corrections made by the rotation gesture
            /// see: https://gist.github.com/AchrafKassioui/bd835b99a78e9ce29b08ce406896c59b
            gesture.setTranslation(.zero, in: theView)
            
        } else if gesture.state == .ended {
            
            /// at the end of the gesture, calculate the velocity to apply inertia.
            /// we devide by an arbitrary factor for better user experience
            cameraPositionVelocity.x = self.xScale * gesture.velocity(in: theView).x / 100
            cameraPositionVelocity.y = self.yScale * gesture.velocity(in: theView).y / 100
            
        } else if gesture.state == .cancelled {
            
            /// if the gesture is cancelled, revert to the camera's position at the beginning of the gesture
            self.position = cameraPositionBeforePan
            
        }
    }
    
    // MARK: Scale
    
    /// zoom state
    private var cameraScaleBeforePinch: (x: CGFloat, y: CGFloat) = (1, 1)
    private var cameraPositionBeforePinch = CGPoint.zero
    private var cameraScaleVelocity: (x: CGFloat, y: CGFloat) = (0, 0)
    
    @objc private func scaleCamera(gesture: UIPinchGestureRecognizer) {
        guard let scene = theScene else { return }
        let scaleCenterInView = gesture.location(in: theView)
        let scaleCenterInScene = scene.convertPoint(fromView: scaleCenterInView)
        
        if gesture.state == .began {
            
            cameraScaleBeforePinch.x = self.xScale
            cameraScaleBeforePinch.y = self.yScale
            cameraPositionBeforePinch = self.position
            
        } else if gesture.state == .changed {
            
            /// respect the base scaling ratio
            let newXScale = (self.xScale / gesture.scale)
            let newYScale = (self.yScale / gesture.scale)
            
            /// limit the resulting scale within a range
            let clampedXScale = max(min(newXScale, cameraMaxScale), cameraMinScale)
            let clampedYScale = max(min(newYScale, cameraMaxScale), cameraMinScale)
            
            /// calculate a factor to move the camera toward the pinch midpoint
            let xTranslationFactor = clampedXScale / self.xScale
            let yTranslationFactor = clampedYScale / self.yScale
            let newCamPosX = scaleCenterInScene.x + (self.position.x - scaleCenterInScene.x) * xTranslationFactor
            let newCamPosY = scaleCenterInScene.y + (self.position.y - scaleCenterInScene.y) * yTranslationFactor
            
            /// update camera scale and position
            self.xScale = clampedXScale
            self.yScale = clampedYScale
            self.position = CGPoint(x: newCamPosX, y: newCamPosY)
            
            /// reset the gesture scale delta
            gesture.scale = 1.0
            
        } else if gesture.state == .ended {
            
            cameraScaleVelocity.x = self.xScale * gesture.velocity / 100
            cameraScaleVelocity.y = self.xScale * gesture.velocity / 100
            
        } else if gesture.state == .cancelled {
            
            self.xScale = cameraScaleBeforePinch.x
            self.yScale = cameraScaleBeforePinch.y
            self.position = cameraPositionBeforePinch
            
        }
    }
    
    // MARK: Rotate
    
    /// rotation state
    private var cameraRotationBeforeRotate: CGFloat = 0
    private var cameraPositionBeforeRotate = CGPoint.zero
    private var cumulativeRotation: CGFloat = 0
    private var rotationPivot = CGPoint.zero
    private var cameraRotationVelocity: CGFloat = 0
    
    @objc private func rotateCamera(gesture: UIRotationGestureRecognizer) {
        guard let scene = theScene else { return }
        let midpointInView = gesture.location(in: theView)
        let midpointInScene = scene.convertPoint(fromView: midpointInView)
        
        if gesture.state == .began {
            
            cameraRotationBeforeRotate = self.zRotation
            cameraPositionBeforeRotate = self.position
            rotationPivot = midpointInScene
            cumulativeRotation = 0
            
        } else if gesture.state == .changed {
            
            /// update camera rotation
            self.zRotation = gesture.rotation + cameraRotationBeforeRotate
            
            /// store the rotation change since the last change
            /// needed to update the camera position live
            let rotationDelta = gesture.rotation - cumulativeRotation
            cumulativeRotation += rotationDelta
            
            /// Calculate how the camera should be moved to simulate rotation around the gesture midpoint
            let offsetX = self.position.x - rotationPivot.x
            let offsetY = self.position.y - rotationPivot.y
            
            let rotatedOffsetX = cos(rotationDelta) * offsetX - sin(rotationDelta) * offsetY
            let rotatedOffsetY = sin(rotationDelta) * offsetX + cos(rotationDelta) * offsetY
            
            let newCameraPositionX = rotationPivot.x + rotatedOffsetX
            let newCameraPositionY = rotationPivot.y + rotatedOffsetY
            
            self.position.x = newCameraPositionX
            self.position.y = newCameraPositionY
            
        } else if gesture.state == .ended {
            
            cameraRotationVelocity = self.xScale * gesture.velocity / 100
            
        } else if gesture.state == .cancelled {
            
            self.zRotation = cameraRotationBeforeRotate
            self.position = cameraPositionBeforeRotate
            
        }
    }
    
    // MARK: Update velocity
    
    /// this function is called to stop any ongoing camera inertia
    /// typically called on a touchBegan event in the parent scene
    func stopInertia() {
        cameraScaleVelocity = (0.0, 0.0)
        cameraPositionVelocity = (0.0, 0.0)
        cameraRotationVelocity = 0
    }
    
    func updateInertia() {
        
        /// reduce the load by checking the current scale velocity first
        if (enableScaleInertia && (cameraScaleVelocity.x != 0 || cameraScaleVelocity.y != 0)) {
            /// Apply friction to velocity so the camera slows to a stop when user interaction ends.
            cameraScaleVelocity.x *= cameraScaleInertia
            cameraScaleVelocity.y *= cameraScaleInertia
            
            /// Stop the camera when velocity has approached close enough to zero
            if (abs(cameraScaleVelocity.x) < 0.001) { cameraScaleVelocity.x = 0 }
            if (abs(cameraScaleVelocity.y) < 0.001) { cameraScaleVelocity.y = 0 }
            
            let newXScale = self.xScale - cameraScaleVelocity.x
            let newYScale = self.yScale - cameraScaleVelocity.y
            
            /// prevent the inertial zooming from exceeding the zoom limits
            let clampedXScale = max(min(newXScale, cameraMaxScale), cameraMinScale)
            let clampedYScale = max(min(newYScale, cameraMaxScale), cameraMinScale)
            
            self.xScale = clampedXScale
            self.yScale = clampedYScale
        }
        
        /// reduce the load by checking the current position velocity first
        if (enablePanInertia && (cameraPositionVelocity.x != 0 || cameraPositionVelocity.y != 0)) {
            /// apply friction to velocity
            cameraPositionVelocity.x *= cameraPositionInertia
            cameraPositionVelocity.y *= cameraPositionInertia
            
            /// calculate the rotated velocity to account for camera rotation
            let angle = self.zRotation
            let rotatedVelocityX = cameraPositionVelocity.x * cos(angle) + cameraPositionVelocity.y * sin(angle)
            let rotatedVelocityY = -cameraPositionVelocity.x * sin(angle) + cameraPositionVelocity.y * cos(angle)
            
            /// Stop the camera when velocity is near zero to prevent oscillation
            if abs(cameraPositionVelocity.x) < 0.01 { cameraPositionVelocity.x = 0 }
            if abs(cameraPositionVelocity.y) < 0.01 { cameraPositionVelocity.y = 0 }
            
            /// Update the camera's position with the rotated velocity
            self.position.x -= rotatedVelocityX
            self.position.y += rotatedVelocityY
        }
        
        /// reduce the load by checking the current scale velocity first
        if (enableRotationInertia && cameraRotationVelocity != 0) {
            /// Apply friction to velocity so the camera slows to a stop when user interaction ends
            cameraRotationVelocity *= cameraRotationInertia
            
            /// Stop the camera when velocity has approached close enough to zero
            if (abs(cameraRotationVelocity) < 0.01) {
                cameraRotationVelocity = 0
            }
            
            self.zRotation += cameraRotationVelocity
        }
    }
    
    // MARK: Gesture recognizers
    
    private func setupGestureRecognizers(in view: SKView) {
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panCamera(gesture:)))
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(scaleCamera(gesture:)))
        let rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotateCamera(gesture:)))
        
        panRecognizer.delegate = self
        pinchRecognizer.delegate = self
        rotationRecognizer.delegate = self
        
        panRecognizer.maximumNumberOfTouches = 2
        
        /// this prevents the recognizer from cancelling touch events once a gesture is recognized
        /// In UIKit, this property is set to true by default
        panRecognizer.cancelsTouchesInView = false
        pinchRecognizer.cancelsTouchesInView = false
        rotationRecognizer.cancelsTouchesInView = false
        
        view.addGestureRecognizer(panRecognizer)
        view.addGestureRecognizer(pinchRecognizer)
        view.addGestureRecognizer(rotationRecognizer)
    }
    
    /// allow multiple gesture recognizers to recognize gestures at the same time
    /// for this function to work, the protocol `UIGestureRecognizerDelegate` must be added to this class
    /// and a delegate must be set on the recognizer that needs to work with others
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /// Use this function to determine if the gesture recognizer should be triggered by the touch event
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        /// here, you can add logic to determine whether the gesture recognizer should fire
        /// for example, if some area is touched, return false to disable the gesture recognition
        /// for this camera, we return true only if the custom lock property is false
        return !lock
    }
}

// MARK: - Gesture visualization

class GestureVisualizationHelper: SKNode {
    
    var gestureVisualizationNodes: [String: SKShapeNode] = [:]
    let circleRadius: CGFloat = 10
    let myFontName: String = "GillSans-SemiBold"
    let myFontColor = SKColor(white: 0, alpha: 0.8)
    
    weak var sceneView: SKView?
    weak var parentScene: SKScene?
    
    init(view: SKView, scene: SKScene) {
        self.sceneView = view
        self.parentScene = scene
        super.init()
        self.setupGestureRecognizers(in: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupGestureRecognizers(in view: SKView) {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(updateGestureVisualization(gesture:)))
        view.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(updateGestureVisualization(gesture:)))
        view.addGestureRecognizer(panGesture)
        
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(updateGestureVisualization(gesture:)))
        view.addGestureRecognizer(rotationGesture)
    }
    
    @objc func updateGestureVisualization(gesture: UIGestureRecognizer) {
        if let pinchGesture = gesture as? UIPinchGestureRecognizer {
            visualizePinchGesture(pinchGesture)
        } else if let panGesture = gesture as? UIPanGestureRecognizer {
            visualizePanGesture(panGesture)
        } else if let rotationGesture = gesture as? UIRotationGestureRecognizer {
            visualizeRotationGesture(rotationGesture)
        }
        
        if gesture.state == .ended || gesture.state == .cancelled {
            clearGestureVisualization()
        }
    }
    
    private func visualizePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard let scene = parentScene else { return }
        let nodeName = "pinch-center"
        let pinchCenterInView = gesture.location(in: self.sceneView)
        let pinchCenterInScene = scene.convertPoint(fromView: pinchCenterInView)
        updateOrCreateVisualizationNode(name: nodeName, position: pinchCenterInScene, color: .systemCyan, showLabel: true)
        
        if gesture.numberOfTouches == 2 {
            for i in 0..<2 {
                let touchLocationInView = gesture.location(ofTouch: i, in: self.sceneView)
                let touchLocationInScene = scene.convertPoint(fromView: touchLocationInView)
                updateOrCreateVisualizationNode(name: "pinch-touch-\(i)", position: touchLocationInScene, color: .systemGray, showLabel: false)
            }
        }
    }
    
    private func visualizePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let scene = parentScene else { return }
        let nodeName = "pan-point"
        let panPointInView = gesture.location(in: self.sceneView)
        let panPointInScene = scene.convertPoint(fromView: panPointInView)
        updateOrCreateVisualizationNode(name: nodeName, position: panPointInScene, color: .systemBlue, showLabel: true)
    }
    
    private func visualizeRotationGesture(_ gesture: UIRotationGestureRecognizer) {
        guard let scene = parentScene else { return }
        let rotationCenterInView = gesture.location(in: self.sceneView)
        let rotationCenterInScene = scene.convertPoint(fromView: rotationCenterInView)
        updateOrCreateVisualizationNode(name: "rotation-center", position: rotationCenterInScene, color: .systemRed, showLabel: true)
        
        if gesture.numberOfTouches == 2 {
            for i in 0..<2 {
                let touchLocationInView = gesture.location(ofTouch: i, in: self.sceneView)
                let touchLocationInScene = scene.convertPoint(fromView: touchLocationInView)
                updateOrCreateVisualizationNode(name: "rotation-touch-\(i)", position: touchLocationInScene, color: .systemGreen, showLabel: true)
            }
        }
    }
    
    private func updateOrCreateVisualizationNode(name: String, position: CGPoint, color: UIColor, showLabel: Bool) {
        if let node = gestureVisualizationNodes[name] {
            node.position = position
        } else {
            let node = SKShapeNode(circleOfRadius: circleRadius)
            node.fillColor = color
            node.strokeColor = .white
            node.name = name
            node.zPosition = 9999
            node.position = position
            addChild(node)
            
            if showLabel{
                let label = SKLabelNode(text: name)
                label.fontName = myFontName
                label.fontColor = myFontColor
                label.fontSize = 12
                label.preferredMaxLayoutWidth = 60
                label.numberOfLines = 0
                label.verticalAlignmentMode = .center
                node.addChild(label)
            }
            gestureVisualizationNodes[name] = node
        }
    }
    
    func clearGestureVisualization() {
        gestureVisualizationNodes.values.forEach { $0.removeFromParent() }
        gestureVisualizationNodes.removeAll()
    }
}


