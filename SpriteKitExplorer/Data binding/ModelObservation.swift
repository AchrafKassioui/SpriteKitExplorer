/**
 
 # Swift Observation
 
 Data model observation between SpriteKit and SwiftUI
 
 Achraf Kassioui
 Created: 17 June 2024
 Updated: 17 June 2024
 
 */
import SwiftUI
import SpriteKit


enum SpriteType {
    case rectangle
    case disc
}

struct SpriteItem: View {
    @State private var offset: CGSize = .zero
    @State var isDragging = false
    let side: Double = 60
    
    let spriteType: SpriteType
    let onRelease: (CGPoint) -> Void
    
    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: side, height: side)
            .overlay(
                Group {
                    switch spriteType {
                    case .rectangle:
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: 56, height: 56)
                    case .disc:
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: side, height: side)
                    }
                }
            )
            .shadow(color: .black.opacity(0.2), radius: isDragging ? 12 : 0, x: 0, y: isDragging ? 8 : 0)
            .offset(offset)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { gesture in
                        isDragging = true
                        offset = gesture.translation
                    }
                    .onEnded { gesture in
                        onRelease(gesture.location)
                        offset = .zero
                        isDragging = false
                    }
            )
    }
}

struct SpriteDrawer: View {
    let myScene: ModelObservationScene
    
    var body: some View {
        HStack (spacing: 22) {
            SpriteItem(spriteType: .rectangle) { releasePosition in
                let positionInScene = myScene.convertPoint(fromView: releasePosition)
                myScene.createSprite(spriteType: .rectangle, position: positionInScene)
            }
            
            SpriteItem(spriteType: .disc) { releasePosition in
                let positionInScene = myScene.convertPoint(fromView: releasePosition)
                myScene.createSprite(spriteType: .disc, position: positionInScene)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .stroke(.black.opacity(0.6), lineWidth: 0.5)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        )
    }
}

struct ModelObservationView: View {
    @State var myScene = ModelObservationScene()
    @State var addButtonOffset: CGSize = .zero
    @State var positionInView: CGPoint = .zero
    @State var isDrawerShown = true
    
    var body: some View {
        GeometryReader { geoProxy in
            ZStack {
                SpriteView(
                    scene: myScene,
                    options: [.allowsTransparency],
                    debugOptions: [.showsFPS]
                )
                .coordinateSpace(.named("SpriteView"))
                
                VStack {
                    Spacer()
                    
                    VStack {
                        SpriteDrawer(myScene: myScene)
                            .opacity(isDrawerShown ? 1 : 0)
                            .offset(y: isDrawerShown ? 0 : 20)
                            .animation(.bouncy(duration: 0.2), value: isDrawerShown)
                        
                        HStack {
                            Button(action: {
                                isDrawerShown.toggle()
                            }, label: {
                                Image("plus-icon")
                                    .renderingMode(.template)
                                    .rotationEffect(isDrawerShown ? Angle(degrees: 45) : .zero)
                                    .animation(.bouncy(duration: 0.2), value: isDrawerShown)
                            })
                            .buttonStyle(iconNoBackground())
                            
                        } // End Right Palette VStack
                        .frame(minWidth: 60, minHeight: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .stroke(.opacity(0.6), lineWidth: 0.5)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
                        )
                    } // End bottom HStack of UI layer
                    //.padding()
                    
                } // End UI layer VStack
                .padding(.leading, geoProxy.safeAreaInsets.leading)
                .padding(.top, geoProxy.safeAreaInsets.top)
                .padding(.trailing, geoProxy.safeAreaInsets.trailing)
                .padding(.bottom, geoProxy.safeAreaInsets.bottom)
                
            } // End Main ZStack
            .ignoresSafeArea()
            .background(.gray)
        }
    }
}

#Preview {
    ModelObservationView()
}

@Observable
class ModelObservationModel {
    struct Sprite {
        var id: UUID
        var spriteType: SpriteType
        var position: CGPoint
    }
    
    var sprites: [Sprite] = []
    
    var isDagging = false
}

class ModelObservationScene: SKScene {
    
    var model = ModelObservationModel()
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
    }
    
    func createSprite(spriteType: SpriteType, position: CGPoint) {
        let sprite: SKSpriteNode
        let id = UUID()
        
        switch spriteType {
        case .rectangle:
            sprite = DraggableSprite(texture: nil, color: .systemYellow, size: CGSize(width: 60, height: 60), delay: 1)
        case .disc:
            sprite = DraggableSprite(texture: SKTexture(imageNamed: "circle-30-fill"), color: .systemYellow, size: CGSize(width: 60, height: 60))
        }
        sprite.name = id.uuidString
        sprite.position = position
        
        let spriteModel = ModelObservationModel.Sprite(id: id, spriteType: spriteType, position: position)
        model.sprites.append(spriteModel)
        
        addChild(sprite)
        let popAction = SKEase.scale(easeFunction: .curveTypeCubic, easeType: .easeTypeOut, time: 0.2, from: 1, to: 1)
        sprite.run(popAction)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
}

