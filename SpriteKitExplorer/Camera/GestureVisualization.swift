/**
 
 # Gesture Visualization
 
 Achraf Kassioui
 Created: 23 April 2024
 Updated: 23 April 2024
 
 */

import SpriteKit

class GestureVisualizationHelper: SKNode {
    
    private var gestureVisualizationNodes: [String: SKShapeNode] = [:]
    private let circleRadius: CGFloat = 22
    private let myFontName: String = "GillSans-SemiBold"
    private let myFontColor = SKColor(white: 0, alpha: 0.8)
    
    weak var theView: SKView?
    weak var theScene: SKScene?
    
    init(view: SKView, scene: SKScene) {
        self.theView = view
        self.theScene = scene
        super.init()
        self.setupGestureRecognizers(in: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupGestureRecognizers(in view: SKView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(updateGestureVisualization(gesture:)))
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(updateGestureVisualization(gesture:)))
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(updateGestureVisualization(gesture:)))
        
        view.addGestureRecognizer(panGesture)
        view.addGestureRecognizer(pinchGesture)
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
        guard let scene = theScene else { return }
        let nodeName = "pinch"
        let pinchCenterInView = gesture.location(in: self.theView)
        let pinchCenterInScene = scene.convertPoint(fromView: pinchCenterInView)
        updateOrCreateVisualizationNode(name: nodeName, position: pinchCenterInScene, color: .systemCyan, showLabel: true)
        
        if gesture.numberOfTouches == 2 {
            for i in 0..<2 {
                let touchLocationInView = gesture.location(ofTouch: i, in: self.theView)
                let touchLocationInScene = scene.convertPoint(fromView: touchLocationInView)
                updateOrCreateVisualizationNode(name: "pinch-touch-\(i)", position: touchLocationInScene, color: .systemGray, showLabel: false)
            }
        }
    }
    
    private func visualizePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let scene = theScene else { return }
        let nodeName = "pan"
        let panPointInView = gesture.location(in: self.theView)
        let panPointInScene = scene.convertPoint(fromView: panPointInView)
        updateOrCreateVisualizationNode(name: nodeName, position: panPointInScene, color: .systemBlue, showLabel: true)
    }
    
    private func visualizeRotationGesture(_ gesture: UIRotationGestureRecognizer) {
        guard let scene = theScene else { return }
        let rotationCenterInView = gesture.location(in: self.theView)
        let rotationCenterInScene = scene.convertPoint(fromView: rotationCenterInView)
        updateOrCreateVisualizationNode(name: "rotation", position: rotationCenterInScene, color: .systemRed, showLabel: true)
        
        if gesture.numberOfTouches == 2 {
            for i in 0..<2 {
                let touchLocationInView = gesture.location(ofTouch: i, in: self.theView)
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
