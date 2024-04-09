//
//  cfewcfwer.swift
//  SpriteKitExplorer
//
//  Created by Achraf Kassioui on 1/4/2024.
//

import SpriteKit

class scraps2: SKScene, UIGestureRecognizerDelegate {
    
    let navigationCamera = SKCameraNode()
    
    // MARK: - Camera zoom
    
    /// zoom settings
    var cameraMaxScale: CGFloat = 100
    var cameraMinScale: CGFloat = 0.01
    var cameraScaleInertia: CGFloat = 0.75
    
    /// zoom state
    var cameraScaleVelocity: CGFloat = 0
    var cameraScaleBeforePinch: CGFloat = 1
    var cameraPositionBeforePinch = CGPoint.zero
    
    func scaleCamera(camera: SKNode, gesture: UIPinchGestureRecognizer) {
        let scaleCenterInView = gesture.location(in: view)
        let scaleCenterInScene = convertPoint(fromView: scaleCenterInView)
        
        if gesture.state == .began {
            cameraScaleBeforePinch = camera.xScale
            cameraPositionBeforePinch = camera.position
        } else if gesture.state == .changed {
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
        } else if gesture.state == .ended {
            cameraScaleVelocity = camera.xScale * gesture.velocity / 100
        } else if gesture.state == .cancelled {
            camera.setScale(cameraScaleBeforePinch)
            camera.position = cameraPositionBeforePinch
        }
    }
    
    // MARK: - Camera pan
    
    /// pan settings
    var cameraPositionInertia: CGFloat = 0.95
    
    /// pan state
    var cameraPositionVelocity: (x: CGFloat, y: CGFloat) = (0, 0)
    var cameraPositionBeforePan = CGPoint.zero
    
    func panCamera(camera: SKNode, gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            cameraPositionBeforePan = camera.position
        } else if gesture.state == .changed {
            let translation = gesture.translation(in: self.view)
            
            /// Calculate adjusted translation based on the current rotation
            let angle = -camera.zRotation
            let dx = translation.x * cos(angle) - translation.y * sin(angle)
            let dy = translation.x * sin(angle) + translation.y * cos(angle)
            
            /// Apply adjusted translation to camera position
            camera.position = CGPoint(x: cameraPositionBeforePan.x - dx * camera.xScale, y: cameraPositionBeforePan.y + dy * camera.yScale)
            
            /// Update the rotation pivot to follow the pan
        } else if gesture.state == .ended {
            /// get the velocity, adjust for zoom level, and divide by an arbitrary factor for better user experience
            cameraPositionVelocity.x = camera.xScale * gesture.velocity(in: self.view).x / 100
            cameraPositionVelocity.y = camera.yScale * gesture.velocity(in: self.view).y / 100
        } else if gesture.state == .cancelled {
            camera.position = cameraPositionBeforePan
        }
    }
    
    // MARK: - Camera rotation
    
    /// rotation settings
    var cameraRotationInertia: CGFloat = 0.95
    
    /// rotation state
    var cameraRotationVelocity: CGFloat = 0
    
    var cameraRotationWhenGestureStarts: CGFloat = 0
    var rotationPivot: CGPoint = .zero
    var cumulativeRotation: CGFloat = 0
    
    func rotateCamera(camera: SKNode, gesture: UIRotationGestureRecognizer) {
        let rotationCenterInView = gesture.location(in: view)
        let rotationCenterInScene = convertPoint(fromView: rotationCenterInView)
        
        if gesture.state == .began {
            
            cameraRotationWhenGestureStarts = camera.zRotation
            rotationPivot = rotationCenterInScene
            cumulativeRotation = 0
            
        } else if gesture.state == .changed {
            
            let rotationSinceLastChange = gesture.rotation - cumulativeRotation
            /// Update cumulative rotation
            cumulativeRotation = gesture.rotation
            
            /// Apply only the change since last update to avoid oscillation
            let currentRotation = camera.zRotation + rotationSinceLastChange
            
            /// To rotate around the pivot, adjust the camera's position
            rotationPivot = rotationCenterInScene
            let dx = camera.position.x - rotationPivot.x
            let dy = camera.position.y - rotationPivot.y
            let distance = sqrt(dx * dx + dy * dy)
            
            /// Update angle based on rotation change
            let angle = atan2(dy, dx) + rotationSinceLastChange
            
            let newCameraX = rotationPivot.x + distance * cos(angle)
            let newCameraY = rotationPivot.y + distance * sin(angle)
            
            camera.zRotation = currentRotation
            camera.position = CGPoint(x: newCameraX, y: newCameraY)
            
        } else if gesture.state == .ended {
            cameraRotationVelocity = camera.xScale * gesture.velocity / 100
        } else if gesture.state == .cancelled {
            camera.zRotation = cameraRotationWhenGestureStarts
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
        
        panRecognizer.maximumNumberOfTouches = 2
        
        //view.addGestureRecognizer(pinchRecognizer)
        //view.addGestureRecognizer(panRecognizer)
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
 
}
