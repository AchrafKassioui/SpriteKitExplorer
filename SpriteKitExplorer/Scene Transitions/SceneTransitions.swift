/**
 
 # SpriteKit scene transitions
 
 In SpriteKit, we can use SKTransition to replace one scene with another.
 
 Created: 16 March 2024
 Updated: 16 October 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

struct SceneTransitionsView: View {
    var myScene = SceneToTransitionFrom()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    SceneTransitionsView()
}

// MARK: Scene Transitions Catalog

/// Use lazy properties to ensure the transitions are created only when accessed
struct TransitionManager {
    static var transitionEffect1: SKTransition {
        SKTransition.push(with: .down, duration: 0.5)
    }
    
    static var transitionEffect2: SKTransition {
        SKTransition.doorway(withDuration: 1)
    }
    
    static var transitionEffect3: SKTransition {
        SKTransition.flipVertical(withDuration: 0.5)
    }
    
    static var transitionFilter1: CIFilter? {
        CIFilter(name: "CIAccordionFoldTransition", parameters: [
            "inputBottomHeight": 1,
            "inputNumberOfFolds": 5,
            "inputFoldShadowAmount": 1,
            "inputTime": 0.1
        ])
    }
    
    static var transitionFilter2: CIFilter? {
        CIFilter(name: "CIBarsSwipeTransition", parameters: [
            "inputAngle": 3.14,
            "inputWidth": 30,
            "inputBarOffset": 1,
            "inputTime": 0
        ])
    }
    
    static var transitionFilter3: CIFilter? {
        CIFilter(name: "CICopyMachineTransition", parameters: [
            "inputExtent": CIVector(x: 0, y: 0, z: 1170, w: 2532),
            "inputColor": CIColor(red: 0.6, green: 1, blue: 0.8, alpha: 1),
            "inputTime": 1,
            "inputAngle": 1.57,
            "inputWidth": 1170,
            "inputOpacity": 0.5
        ])
    }
    
    static var transitionFilter4: CIFilter? {
        CIFilter(name: "CIFlashTransition", parameters: [
            "inputCenter": CIVector(x: 1170/2, y: 2532/2),
            "inputExtent": CIVector(x: 0, y: 0, z: 30, w: 30),
            "inputColor": CIColor(red: 0.5, green: 0.2, blue: 1, alpha: 1),
            "inputTime": 0,
            "inputMaxStriationRadius": 2.58,
            "inputStriationStrength": 1.5,
            "inputStriationContrast": 1.375,
            "inputFadeThreshold": 0.85
        ])
    }
    
    static var transitionFilter5: CIFilter? {
        CIFilter(name: "CIModTransition", parameters: [
            "inputCenter": CIVector(x: 1170/2, y: 2532/2),
            "inputTime": 0,
            "inputAngle": 0,
            "inputRadius": 30,
            "inputCompression": 2532
        ])
    }
    
    static var transitionFilter6: CIFilter? {
        CIFilter(name: "CIPageCurlWithShadowTransition", parameters: [
            "inputExtent": CIVector(x: 1000, y: 1000, z: 300, w: 300),
            "inputTime": 0,
            "inputAngle": 1.57,
            "inputRadius": 300,
            "inputShadowSize": 0.5,
            "inputShadowAmount": 0.7,
            "inputShadowExtent": CIVector(x: 0, y: 0, z: 300, w: 0)
        ])
    }
    
    static var ciTransition: SKTransition? {
        if let filter = transitionFilter3 {
            return SKTransition(ciFilter: filter, duration: 1)
        }
        return nil
    }
}

// MARK: SpriteKit Scenes

class SceneToTransitionFrom: SKScene {
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scaleMode = .resizeFill
        backgroundColor = .darkGray
        
        let background = SKSpriteNode(imageNamed: "abstract-dunes-1024")
        background.setScale(2.4)
        background.texture?.filteringMode = .nearest
        addChild(background)
        
        let button = createButton()
        addChild(button)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touches = touches.first,
              let view = view,
              let scene = scene else { return }
        
        let touchLocation = touches.location(in: scene)
        let touchedNodes = self.nodes(at: touchLocation)
        for node in touchedNodes {
            if node.name == "button" {
                /// change the transition parameter to try different transition effects
                if let transition = TransitionManager.ciTransition {
                    view.presentScene(SceneToTransitionTo(), transition: transition)
                }
            }
        }
    }
}

class SceneToTransitionTo: SKScene {
    override func didMove(to view: SKView) {
        size = view.bounds.size
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scaleMode = .resizeFill
        backgroundColor = .lightGray
        
        let background = SKSpriteNode(imageNamed: "space-1024")
        background.texture?.filteringMode = .nearest
        background.setScale(3)
        addChild(background)
        
        let button = createButton()
        addChild(button)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touches = touches.first,
              let view = view,
              let scene = scene else { return }
        
        let touchLocation = touches.location(in: scene)
        let touchedNodes = self.nodes(at: touchLocation)
        for node in touchedNodes {
            if node.name == "button" {
                /// change the transition parameter to try different transition effects
                if let transition = TransitionManager.ciTransition {
                    view.presentScene(SceneToTransitionFrom(), transition: transition)
                }
            }
        }
    }
}


fileprivate func createButton() -> SKNode {
    let label = SKLabelNode(text: "Transition Scene")
    label.fontName = "Menlo-Bold"
    label.fontSize = 20
    label.verticalAlignmentMode = .center
    
    let buttonWidth = label.frame.width + 40
    let buttonHeight = label.frame.height + 40
    let button = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 12)
    button.name = "button"
    button.lineWidth = 1.5
    button.strokeColor = SKColor(white: 1, alpha: 0.2)
    button.fillColor = SKColor(white: 1, alpha: 0.1)
    
    button.addChild(label)
    return button
}
