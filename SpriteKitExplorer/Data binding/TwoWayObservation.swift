/**
 
 # Swift Observation
 
 Two-way observation SpriteKit <-> SwiftUI
 
 Achraf Kassioui
 Created: 17 June 2024
 Updated: 17 June 2024
 
 */
import SwiftUI
import SpriteKit

struct TwoWayObservationView: View {
    @State var myScene = TwoWayObservationScene()
    
    var body: some View {
        ZStack {
            SpriteView(scene: myScene, debugOptions: [.showsFPS])
                .ignoresSafeArea()
            VStack {
                Spacer()
                let text = String(describing: Int(myScene.myDataModel.spritePosition.x))
                Text("x: \(text)")
                Slider(
                    value: $myScene.myDataModel.spritePosition.x,
                    in: -200...200,
                    step: 1
                )
                .frame(width: 200)
                .onChange(of: myScene.myDataModel.spritePosition) {
                    myScene.sprite.position = myScene.myDataModel.spritePosition
                }
                .animation(.bouncy, value: myScene.myDataModel.spritePosition.x)
            }
        }
    }
}

#Preview {
    TwoWayObservationView()
}

@Observable
class TwoWayObservationModel {
    var spritePosition: CGPoint = .zero
}

class TwoWayObservationScene: SKScene {
    
    var myDataModel = TwoWayObservationModel()
    var sprite = SKSpriteNode()
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor.gray
        backgroundColor = SKColor(.gray)
        
        sprite = SKSpriteNode(color: .systemYellow, size: CGSize(width: 75, height: 75))
        sprite.position = myDataModel.spritePosition
        addChild(sprite)
    }
    
    func moveSprite(to position: CGPoint) {
        let moveAction = SKAction.move(to: position, duration: 0)
        moveAction.timingMode = .easeInEaseOut
        sprite.run(moveAction) {
            self.myDataModel.spritePosition = self.sprite.position
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            moveSprite(to: touchLocation)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            moveSprite(to: touchLocation)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
}

