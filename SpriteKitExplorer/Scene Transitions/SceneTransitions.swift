//
//  SceneTransitions.swift
//  SpriteKitExplorer
//
//  Created by Achraf Kassioui on 16/3/2024.
//

/**
 
 # SpriteKit scene transitions
 
 In SpriteKit, we can use SKTransition to replace one scene with another
 
 Created: 16 March 2024
 
 */

import SwiftUI
import SpriteKit

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

/// a list of different transtion effects

//enum TransitionEffect {
//    case pushDown(duration: TimeInterval)
//    case pushUp(duration: TimeInterval)
//    case pushLeft(duration: TimeInterval)
//    case pushRight(duration: TimeInterval)
//    case doorway(duration: TimeInterval)
//    case pushUp(duration: TimeInterval)
//    case pushUp(duration: TimeInterval)
//    
//    var transition: SKTransition {
//        switch self {
//        case .pushDown(let duration):
//            return SKTransition.push(with: .down, duration: duration)
//        case .pushUp(let duration):
//            return SKTransition.push(with: .up, duration: duration)
//        case .pushUp(let duration):
//            return SKTransition.push(with: .up, duration: duration)
//        case .pushUp(let duration):
//            return SKTransition.push(with: .up, duration: duration)
//        case .pushUp(let duration):
//            return SKTransition.push(with: .up, duration: duration)
//        case .pushUp(let duration):
//            return SKTransition.push(with: .up, duration: duration)
//        case .pushUp(let duration):
//            return SKTransition.push(with: .up, duration: duration)
//        }
//    }
//    
//}

let transitionEffect1 = SKTransition.push(with: .down, duration: 0.5)
let transitionEffect2 = SKTransition.doorway(withDuration: 1)
let transitionEffect3 = SKTransition.flipVertical(withDuration: 0.5)

let transitionFilter1 = CIFilter(
    name: "CIAccordionFoldTransition",
    parameters: [
        "inputBottomHeight": 1,
        "inputNumberOfFolds": 5,
        "inputFoldShadowAmount": 1,
        "inputTime": 0.1
    ]
)
let transitionFilter2 = CIFilter(
    name: "CIBarsSwipeTransition",
    parameters: [
        "inputAngle": 3.14,
        "inputWidth": 30,
        "inputBarOffset": 1,
        "inputTime": 0
    ]
)
let transitionFilter3 = CIFilter(
    name: "CICopyMachineTransition",
    parameters: [
        "inputExtent": CIVector(x: 0, y: 0, z: 1170, w: 2532),
        "inputColor": CIColor(red: 0.6, green: 1, blue: 0.8, alpha: 1),
        "inputTime": 1,
        "inputAngle": 1.57,
        "inputWidth": 1170,
        "inputOpacity": 0.5,
    ]
)
let transitionFilter4 = CIFilter(
    name: "CIFlashTransition",
    parameters: [
        "inputCenter": CIVector(x: 1170/2, y: 2532/2),
        "inputExtent": CIVector(x: 0, y: 0, z: 30, w: 30),
        "inputColor": CIColor(red: 0.5, green: 0.2, blue: 1, alpha: 1),
        "inputTime": 0,
        "inputMaxStriationRadius": 2.58,
        "inputStriationStrength": 1.5,
        "inputStriationContrast": 1.375,
        "inputFadeThreshold": 0.85
    ]
)
let transitionFilter5 = CIFilter(
    name: "CIModTransition",
    parameters: [
        "inputCenter": CIVector(x: 1170/2, y: 2532/2),
        "inputTime": 0,
        "inputAngle": 0,
        "inputRadius": 30,
        "inputCompression": 2532
    ]
)
let transitionFilter6 = CIFilter(
    name: "CIPageCurlWithShadowTransition",
    parameters: [
        "inputExtent": CIVector(x: 1000, y: 1000, z: 300, w: 300),
        "inputTime": 0,
        "inputAngle": 1.57,
        "inputRadius": 300,
        "inputShadowSize": 0.5,
        "inputShadowAmount": 0.7,
        "inputShadowExtent": CIVector(x: 0, y: 0, z: 300, w: 0)
    ]
)
let CITransition = SKTransition.init(ciFilter: transitionFilter3!, duration: 1)

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
                view.presentScene(SceneToTransitionTo(), transition: CITransition)
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
                view.presentScene(SceneToTransitionFrom(), transition: CITransition)
            }
        }
    }
}

func createButton() -> SKNode {
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
