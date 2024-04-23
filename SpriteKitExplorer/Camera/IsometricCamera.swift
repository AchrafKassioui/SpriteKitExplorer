/**
 
 # SpriteKit Isometric Camera
 
 A camera for SpriteKit.
 With this camera, a SpriteKit scene becomes an infinite canvas that you can navigate freely using multi-touch gestures.
 It supports panning, pinching, and rotating. Inertial momentum can be enabled for each.
 
 ## Setup
 
 See InertialCamera
 
 ## Isometric projection
 
 This custom camera is set up such as its user-defined scaling should be respected.
 For example, if you manually start the camera with:
 
 ```
 myCamera.xScale = 0.75
 myCamera.yScale = 1
 ```
 
 Subsequent transformations (position, scale, and rotation) should not modify the ratio between x and y.
 
 ## Challenges
 
 Implementing simulataneous pan and rotation has been a challenge. See: https://gist.github.com/AchrafKassioui/bd835b99a78e9ce29b08ce406896c59b
 
 
 Achraf Kassioui
 Created: 8 April 2024
 Updated: 8 April 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - Live preview

struct IsometricCameraView: View {
    var myScene = IsometricCameraScene()
    
    var body: some View {
        SpriteView(
            scene: myScene,
            preferredFramesPerSecond: 120,
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
            debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS]
        )
        .background(.gray)
        .ignoresSafeArea()
    }
}

#Preview {
    IsometricCameraView()
}

// MARK: - Demo scene

class IsometricCameraScene: SKScene, UIGestureRecognizerDelegate {
    
    override func didMove(to view: SKView) {
        /// configure view
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.89, green: 0.89, blue: 0.84, alpha: 1)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.speed = 0
        let physicsBoundaries = CGRect(
            x: -view.frame.width / 2,
            y: -view.frame.height / 2,
            width: view.frame.width,
            height: view.frame.height
        )
        physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBoundaries)
        physicsBody?.restitution = 1
        
        /// create objects
        let sprite = SKSpriteNode(color: .systemRed, size: CGSize(width: 60, height: 60))
        sprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 60, height: 60))
        sprite.physicsBody?.restitution = 1
        sprite.physicsBody?.linearDamping = 0
        sprite.zPosition = 10
        sprite.position.y = 300
        sprite.zRotation = .pi * 0.25
        addChild(sprite)
        
        let gridTexture = generateGridTexture(cellSize: 60, rows: 20, cols: 20, color: SKColor(white: 0, alpha: 0.15))
        let gridbackground = SKSpriteNode(texture: gridTexture)
        gridbackground.zPosition = -1
        addChild(gridbackground)
        
        let container = SKShapeNode(rectOf: CGSize(width: view.frame.width, height: view.frame.height))
        container.lineWidth = 3
        container.strokeColor = SKColor(white: 0, alpha: 0.9)
        addChild(container)
        
        /// create camera
        let inertialCamera = IsometricCamera(view: view, scene: self)
        camera = inertialCamera
        addChild(inertialCamera)
        inertialCamera.zPosition = 99999
        
        /// create visualization
        let gestureVisualizationHelper = GestureVisualizationHelper(view: view, scene: self)
        addChild(gestureVisualizationHelper)
        
        /// create UI
        createResetCameraButton(with: view)
        createIsometricCameraButton(with: view)
    }
    
    // MARK: UI
    
    let spacing: CGFloat = 20
    let buttonSize = CGSize(width: 60, height: 60)
    
    func createResetCameraButton(with view: SKView) {
        let resetCameraButton = ButtonWithIconAndPattern(
            size: buttonSize,
            icon1: "arrow.counterclockwise",
            icon2: "arrow.counterclockwise",
            iconSize: CGSize(width: 20, height: 24),
            onTouch: resetCamera
        )
        
        resetCameraButton.position = CGPoint(
            x: -view.frame.width/2 + view.safeAreaInsets.left + buttonSize.width/2 + spacing,
            y: -view.frame.height/2 + view.safeAreaInsets.bottom + buttonSize.height/2 + spacing
        )
        
        camera?.addChild(resetCameraButton)
    }
    
    func resetCamera(){
        if let inertialCamera = self.camera as? IsometricCamera {
            inertialCamera.stopInertia()
            inertialCamera.setCameraTo(
                position: .zero,
                xScale: 1,
                yScale: 1,
                rotation: 0
            )
        }
    }
    
    func createIsometricCameraButton(with view: SKView) {
        let switchCameraProjectionButton = ButtonWithIconAndPattern(
            size: buttonSize,
            icon1: "move.3d",
            icon2: "move.3d",
            iconSize: CGSize(width: 20, height: 20),
            onTouch: switchCameraProjection
        )
        
        switchCameraProjectionButton.position = CGPoint(
            x: -view.frame.width/2 + view.safeAreaInsets.left + buttonSize.width * 2,
            y: -view.frame.height/2 + view.safeAreaInsets.bottom + buttonSize.height/2 + spacing
        )
        
        camera?.addChild(switchCameraProjectionButton)
    }
    
    func switchCameraProjection() {
        if let inertialCamera = camera as? IsometricCamera {
            inertialCamera.isometric.toggle()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? IsometricCamera {
            inertialCamera.updateInertialVelocity()
        }
    }
    
}


// MARK: - Isometric camera class

class IsometricCamera: SKCameraNode, UIGestureRecognizerDelegate {
    
    weak private var sceneView: SKView?
    weak private var parentScene: SKScene?
    
    var enablePanInertia = true
    var enableScaleInertia = true
    var enableRotationInertia = true
    
    /// Initialize the camera with a reference to the containing view and scene
    init(view: SKView, scene: SKScene) {
        self.sceneView = view
        self.parentScene = scene
        
        super.init()
        
        self.isometric = false
        self.setupGestureRecognizers(in: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Set camera
    
    func setCameraTo(position: CGPoint, xScale: CGFloat, yScale: CGFloat, rotation: CGFloat) {
        self.position = position
        self.xScale = xScale
        self.yScale = yScale
        self.zRotation = rotation
    }
    
    private var isIsometric = false
    private let isometricScaleMultiplier = 0.75
    private let isometricRotation = CGFloat(-45).degreesToRadians()  // 45 degrees
    
    var isometric: Bool {
        get { return isIsometric }
        set {
            if isIsometric != newValue {
                isIsometric = newValue
                
                let targetXScale = isIsometric ? xScale * isometricScaleMultiplier : xScale / isometricScaleMultiplier
                let targetRotation = isIsometric ? isometricRotation : 0
                
                let scaleAction = SKAction.scaleX(to: targetXScale, duration: 0.3)
                let rotateAction = SKAction.rotate(toAngle: targetRotation, duration: 0.3)
                
                run(SKAction.group([scaleAction, rotateAction]))
            }
        }
    }
    
    // MARK: Filtering mode
    /**
     
     We change the filtering mode of the renderer depending on camera scale.
     When the scale is below 1 (zoom in), we disable linear filtering and anti aliasing.
     When the scale is 1 or above (zoom out), we enable linear filtering and anti aliasing.
     
     */
    private var wasCameraScaleBelowOne: Bool? = nil
    
    private func updateFilteringModeBasedOnCameraScale(cameraScale: CGFloat) {
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
    
    // MARK: Pan
    
    /// pan settings
    var cameraPositionInertia: CGFloat = 0.95
    
    /// pan state
    private var cameraPositionBeforePan = CGPoint.zero
    private var cameraPositionVelocity: (x: CGFloat, y: CGFloat) = (0, 0)
    
    @objc private func panCamera(gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            
            /// store the camera's position at the beginning of the pan gesture
            cameraPositionBeforePan = self.position
            
        } else if gesture.state == .changed {
            
            /// convert UIKit translation coordinates into SpriteKit's coordinate system for better mathematical clarity further down
            let uiKitTranslation = gesture.translation(in: sceneView)
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
            /// we moves the camera opposite to the gesture direction (-dx and -dy), giving the impression of moving the scene itself.
            /// if we want direct manipulation of a node, dx and dy would be added instead of subtracted.
            self.position = CGPoint(
                x: self.position.x - dx * self.xScale,
                y: self.position.y - dy * self.yScale
            )
            
            gesture.setTranslation(.zero, in: sceneView)
            
        } else if gesture.state == .ended {
            
            /// at the end of the gesture, calculate the velocity to apply inertia. We devide by an arbitrary factor for better user experience
            cameraPositionVelocity.x = self.xScale * gesture.velocity(in: sceneView).x / 100
            cameraPositionVelocity.y = self.yScale * gesture.velocity(in: sceneView).y / 100
            
        } else if gesture.state == .cancelled {
            
            /// if the gesture is cancelled, revert to the camera's position at the beginning of the gesture
            self.position = cameraPositionBeforePan
            
        }
    }
    
    // MARK: Scale
    
    /// zoom settings
    var cameraMaxScale: CGFloat = 100
    var cameraMinScale: CGFloat = 0.01
    var cameraScaleInertia: CGFloat = 0.75
    
    /// zoom state
    private var cameraScaleBeforePinch: CGFloat = 1
    private var cameraPositionBeforePinch = CGPoint.zero
    private var cameraScaleVelocity: (x: CGFloat, y: CGFloat) = (0, 0)
    
    @objc private func scaleCamera(gesture: UIPinchGestureRecognizer) {
        guard let scene = parentScene else { return }
        let scaleCenterInView = gesture.location(in: sceneView)
        let scaleCenterInScene = scene.convertPoint(fromView: scaleCenterInView)
        
        if gesture.state == .began {
            
            cameraScaleBeforePinch = self.xScale
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
            
            /*
             /// calculate the new scale, and clamp within the range
             let newScale = self.xScale / gesture.scale
             let clampedScale = max(min(newScale, cameraMaxScale), cameraMinScale)
             
             /// calculate a factor to move the camera toward the pinch midpoint
             let translationFactor = clampedScale / self.xScale
             let newCamPosX = scaleCenterInScene.x + (self.position.x - scaleCenterInScene.x) * translationFactor
             let newCamPosY = scaleCenterInScene.y + (self.position.y - scaleCenterInScene.y) * translationFactor
             
             /// update camera's scale and position
             /// setScale must be called now and no earlier
             self.setScale(clampedScale)
             self.position = CGPoint(x: newCamPosX, y: newCamPosY)
             
             gesture.scale = 1.0
             */
            
        } else if gesture.state == .ended {
            
            cameraScaleVelocity.x = self.xScale * gesture.velocity / 100
            cameraScaleVelocity.y = self.xScale * gesture.velocity / 100
            
        } else if gesture.state == .cancelled {
            
            self.setScale(cameraScaleBeforePinch)
            self.position = cameraPositionBeforePinch
            
        }
    }
    
    // MARK: Rotate
    
    /// rotation settings
    var cameraRotationInertia: CGFloat = 0.85
    
    /// rotation state
    private var cameraRotationBeforeRotate: CGFloat = 0
    private var cameraPositionBeforeRotate = CGPoint.zero
    private var cumulativeRotation: CGFloat = 0
    private var rotationPivot = CGPoint.zero
    private var cameraRotationVelocity: CGFloat = 0
    
    @objc private func rotateCamera(gesture: UIRotationGestureRecognizer) {
        guard let scene = parentScene else { return }
        let midpointInView = gesture.location(in: sceneView)
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
            
            /// Calculate how the camera should be moved
            
            let offsetX = self.position.x - rotationPivot.x
            let offsetY = self.position.y - rotationPivot.y
            
            let rotatedOffsetX = cos(rotationDelta) * offsetX - sin(rotationDelta) * offsetY
            let rotatedOffsetY = sin(rotationDelta) * offsetX + cos(rotationDelta) * offsetY
            
            let newCameraPositionX = rotationPivot.x + rotatedOffsetX
            let newCameraPositionY = rotationPivot.y + rotatedOffsetY
            
            self.position = CGPoint(
                x: newCameraPositionX,
                y: newCameraPositionY
            )
            
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
    
    func updateInertialVelocity() {
        
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
            
            /// update texture filtering mode based on camera scale
            /// optimize this call, so it isn't called every step
            updateFilteringModeBasedOnCameraScale(cameraScale: self.xScale)
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
        
        /// this prevents the recognizer from cancelling basic touch events once a gesture is recognized
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
    
    /// why did I add this??
    /// Use this function to determine if the gesture recognizer should handle the touch
    /// For example, return false if the touch is within a certain area that should only respond to direct touch events
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}
