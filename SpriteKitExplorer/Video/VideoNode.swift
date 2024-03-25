/**
 
 # SKVideoNode
 
 This file adds a video node to the scene by using `SKVideoNode(fileNamed: "")`
 Core Image filters are applied to the video with an `SKEffectNode` parent node
 
 Created: 22 March 2024
 
 */

import SwiftUI
import SpriteKit
import CoreImage.CIFilterBuiltins

struct VideoNodeView: View {
    var myScene = VideoNodeScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS, .showsPhysics]
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    VideoNodeView()
}

class VideoNodeScene: SKScene {
    
    // MARK: - Scene setup
    
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .gray
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        setupCamera()
        addVideoNode()
        createImageFiltersUI()
    }
    
    func setupCamera() {
        let camera = SKCameraNode()
        camera.name = "camera"
        let viewSize = view?.bounds.size
        camera.xScale = (viewSize!.width / size.width)
        camera.yScale = (viewSize!.height / size.height)
        addChild(camera)
        scene?.camera = camera
        camera.setScale(1)
    }
    
    // MARK: - Video node
    
    func addVideoNode() {
        /// ⚠️ video file should be included like any file, NOT in the Assets catalog
        let videoNode = SKVideoNode(fileNamed: "Multi-touch typography.mp4")
        videoNode.name = "video-node"
        videoNode.setScale(0.5)
        videoNode.play()
        
        /// effect node to apply Core Image filters on the video
        let videoEffectNode = SKEffectNode()
        videoEffectNode.name = "video-node-effectNode"
        
        videoEffectNode.addChild(videoNode)
        addChild(videoEffectNode)
        
        /// credit info
        let credits = SKLabelNode(text: "Schultzschultzgrafik")
        credits.position.y = -250
        addChild(credits)
    }
    
    // MARK: - Core image filters
    
    func createImageFiltersUI() {
        guard let view = view else { return }
        
        let label = SKLabelNode()
        label.name = "image-filter-button-label"
        label.text = "Image filter"
        label.position.y = -6
        label.fontName = "GillSans-SemiBold"
        label.fontSize = 20
        label.fontColor = SKColor(white: 0, alpha: 1)
        
        let button = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 12)
        button.name = "image-filter-button"
        button.fillColor = SKColor(white: 1, alpha: 0.6)
        button.position.y = view.bounds.height / -2 + button.frame.height / 2 + view.safeAreaInsets.bottom + 20
        
        button.addChild(label)
        addChild(button)
    }
    
    func applyImageFilter(_ touches: Set<UITouch>) {
        guard let scene = scene else { return }
        
        for touch in touches {
            let touchLocation = touch.location(in: scene)
            let touchedNodes = scene.nodes(at: touchLocation)
            for node in touchedNodes {
                if node.name == "image-filter-button" {
                    guard let effectNode = scene.childNode(withName: "//video-node-effectNode") as? SKEffectNode else { return }
                    if effectNode.filter == nil {
                        let myFilter = CIFilter.cmykHalftone()
                        myFilter.width = 10
                        effectNode.filter = ChainCIFilter(filters: [myFilter])
                    } else {
                        effectNode.filter = nil
                    }
                }
            }
        }
    }
    
    func updateCenterPoint() {
        
    }
    
    // MARK: - touch events
    
    var centerPoint = CGPoint(x: 0, y: 0)
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        applyImageFilter(touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            centerPoint = touch.location(in: scene!)
        }
    }
    
}

