/**
 
 # Swift Observation
 
 One-way observation SpriteKit -> SwiftUI
 
 Achraf Kassioui
 Created: 16 June 2024
 Updated: 17 June 2024
 
 */
import SwiftUI
import SpriteKit

struct SpriteKitObservationView2: View {
    var myScene = SpriteKitObservationScene2()
    
    var body: some View {
        ZStack {
            SpriteView(scene: myScene)
                .ignoresSafeArea()
            VStack {
                InfoOverlay(text: myScene.myDataModel.message)
                Spacer()
            }
        }
    }
}

struct InfoOverlay: View {
    var text: String
    
    var body: some View {
        if !text.isEmpty {
            Text(text)
                .foregroundStyle(.white)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.black.opacity(0.8))
                        .shadow(color: .black.opacity(0.3), radius: 12, y: 10)
                )
        }
    }
}

#Preview {
    SpriteKitObservationView2()
}

@Observable
class MyDataModel2 {
    var message: String = ""
}

class SpriteKitObservationScene2: SKScene {
    
    var myDataModel = MyDataModel2()
    var sprite = SKSpriteNode()
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        
        sprite = SKSpriteNode(color: .red, size: CGSize(width: 75, height: 75))
        addChild(sprite)
    }
    
    func moveSprite(to position: CGPoint) {
        let moveAction = SKAction.move(to: position, duration: 0)
        moveAction.timingMode = .easeInEaseOut
        sprite.run(moveAction)
        let text = "x: \(Int(position.x)), y: \(Int(position.y))"
        myDataModel.message = text
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
        myDataModel.message = ""
    }
}
