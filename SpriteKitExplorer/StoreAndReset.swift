/**
 
 # Store and Reset
 
 A setup to explore how to save and restore the state of a scene.
 Work in progress...
 
 Created: 20 January 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct StoreAndReset: View {
    var myScene = StoreAndResetScene()
    
    var body: some View {
        ZStack {
            VStack (spacing: 0) {
                SpriteView(
                    scene: myScene,
                    preferredFramesPerSecond: 120,
                    options: [.ignoresSiblingOrder],
                    debugOptions: [.showsNodeCount, .showsFPS, .showsQuadCount, .showsDrawCount, .showsPhysics]
                )
                .ignoresSafeArea()
                
                HStack {
                    Stepper {
                        Text("Change label")
                    } onIncrement: {
                        myScene.myDataModel.aNumber += 1
                        myScene.updateObjects()
                    } onDecrement: {
                        myScene.myDataModel.aNumber -= 1
                        myScene.updateObjects()
                    }
                    Text(String(myScene.myDataModel.aNumber))
                }
                .padding()
                .background(.regularMaterial)
            }
        }
    }
}

// MARK: - Model

struct SKObject {
    var id = UUID()
}

struct SceneModel {
    var canvasSize: CGSize = CGSize(width: 300, height: 600)
    var aNumber: Int = 20
    var aSprite: SKSpriteNode!
    var aLabel: SKLabelNode!
}

// MARK: - SpriteKit

class StoreAndResetScene: SKScene {
    var myDataModel = SceneModel()
    
    /// Use sceneDidLoad to perform one-time setup
    /// Scene does not have a size yet
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .lightGray
        createObjects()
    }
    
    /// Do not use didMove for one-time setup
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
    }
    
    func createObjects() {
        myDataModel.aSprite = SKSpriteNode(color: .systemYellow, size: CGSize(width: 60, height: 60))
        let randomX = CGFloat.random(in: -myDataModel.canvasSize.width / 2 ... myDataModel.canvasSize.width / 2)
        let randomY = CGFloat.random(in: -myDataModel.canvasSize.height / 2 ... myDataModel.canvasSize.height / 2)
        myDataModel.aSprite.position = CGPoint(x: Int(randomX), y: Int(randomY))
        addChild(myDataModel.aSprite)
        
        myDataModel.aLabel = SKLabelNode(text: String(myDataModel.aNumber))
        myDataModel.aLabel.position = CGPoint(x: 0, y: 0)
        myDataModel.aLabel.verticalAlignmentMode = .baseline
        myDataModel.aLabel.fontColor = .systemRed
        myDataModel.aLabel.fontSize = 32
        myDataModel.aLabel.fontName = "Impact"
        myDataModel.aLabel.zPosition = 10
        addChild(myDataModel.aLabel)
    }
    
    func updateObjects() {
        myDataModel.aLabel.text = String(myDataModel.aNumber)
    }
}

#Preview {
    StoreAndReset()
}
