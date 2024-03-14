/**
 
 # Visualize SpriteKit nodes
 
 A helper method to visualize any drawing node on a SKScene,
 by drawing a rectangle around its bounding box.
 
 Created: 13 March 2024
 
 */

import SpriteKit

// MARK: draw the bounding box of the node's frame
func visualizeFrame(nodeName: String, in scene: SKScene) {
    guard let targetNode = scene.childNode(withName: "//\(nodeName)") else { return }
    
    let visualizationNodeName = "visualizationFrameNode"
    let existingVisualizationNode = scene.childNode(withName: visualizationNodeName) as? SKShapeNode
    
    let frame: CGRect = targetNode.calculateAccumulatedFrame()
    let path = CGPath(rect: frame, transform: nil)
    
    if let visualizationNode = existingVisualizationNode {
        visualizationNode.path = path
    } else {
        let frameNode = SKShapeNode(path: path)
        frameNode.name = visualizationNodeName
        frameNode.lineWidth = 2
        frameNode.strokeColor = SKColor.white
        frameNode.zPosition = 100
        scene.addChild(frameNode)
    }
}
