/**
 
 # Investigating SKTileMapNode Memory Leak
 
 Achraf Kassioui
 Created 22 November 2024
 Updated 22 November 2024
 
 */

import SwiftUI
import SpriteKit

// MARK: SwiftUI

struct LeakInvestigationView: View {
    @State var sceneId = UUID()
    @State var myScene = LeakInvestigationScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene
                ,debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount, .showsQuadCount]
            )
            .id(sceneId)
            .ignoresSafeArea()
            .onAppear {
                print("SpriteView appeared in LeakInvestigationView")
                sceneId = UUID()
            }
            
            VStack {
                Spacer()
                Button("Replace SpriteView Scene") {
                    print("SwiftUI Button Pressed")
                    sceneId = UUID()
                    myScene = LeakInvestigationScene()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .background(Color(SKColor.black))
        .persistentSystemOverlays(.hidden)
    }
}

#Preview {
    LeakInvestigationView()
}

class LeakInvestigationScene: SKScene {
    
    // MARK: Scene Setup
    
    override func didMove(to view: SKView) {
        print("didMove LeakInvestigationScene")
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .gray
        view.isMultipleTouchEnabled = true
        
        if let tileMap = createTileMap() {
            addChild(tileMap)
        }
    }
    
    // MARK: Tile Map
    
    let tileSize = CGSize(width: 32, height: 32)
    let tileSheetTexture = SKTexture(imageNamed: "terrain")
    
    func createTileMap() -> SKTileMapNode? {
        print("createTileMap()")
        let tileMap = SKTileMapNode(tileSet: cachedTileSet, columns: 100, rows: 100, tileSize: tileSize)
        for column in 0..<tileMap.numberOfColumns {
            for row in 0..<tileMap.numberOfRows {
                guard let tileGroup = cachedTileSet.tileGroups.randomElement() else {
                    print("createTileMap() error")
                    return nil
                }
                tileMap.setTileGroup(tileGroup, forColumn: column, row: row)
            }
        }
        return tileMap
    }
    
    // MARK: Cache Tiles
    
    lazy var cachedTileSet: SKTileSet = {
        print("cachedTileSet")
        var tileGroups = [SKTileGroup]()
        let relativeTileSize = CGSize(width: tileSize.width / tileSheetTexture.size().width, height: tileSize.height / tileSheetTexture.size().height)
        
        for idx in 0...2 {
            for jdx in 0...2 {
                let tileTexture = SKTexture(rect: CGRect(
                 x: CGFloat(idx) * relativeTileSize.width,
                 y: CGFloat(jdx) * relativeTileSize.height,
                 width: relativeTileSize.width,
                 height: relativeTileSize.height
                 ), in: tileSheetTexture)
                let tileDefinition = SKTileDefinition(texture: tileTexture, size: tileSize)
                let tileGroup = SKTileGroup(tileDefinition: tileDefinition)
                tileGroups.append(tileGroup)
            }
        }
        return SKTileSet(tileGroups: tileGroups)
    }()
    
    // MARK: Present Scene
    
    func presentSceneAgain() {
        guard let view = self.view else { return }
        print("presentSceneAgain LeakInvestigationScene")
        view.presentScene(LeakInvestigationScene(), transition: .doorway(withDuration: 1))
    }
    
    // MARK: Touch
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            print("\ntouchesBegan LeakInvestigationScene")
            presentSceneAgain()
        }
    }
    
    // MARK: Will Move
    
    override func willMove(from view: SKView) {
        print("willMove LeakInvestigationScene")
    }
    
    // MARK: Deinit
    
    deinit {
        print("deinit LeakInvestigationScene")
    }
}
