//
//  Manipulation.swift
//  SpriteKitExplorer
//
//  Created by Achraf Kassioui on 6/5/2024.
//

import SwiftUI
import SpriteKit

// MARK: - SwiftUI View

struct ManipulationView: View {
    @State private var sceneId = UUID()
    @State private var isPaused: Bool = false
    @State private var isCameraLocked: Bool = true
    @State private var isDebugON: Bool = false
    @State private var isSheetON: Bool = false
    var myScene = ManipulationScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes]
            )
            .id(sceneId)
            .onAppear {
                sceneId = UUID()
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                HStack {
                    leftPalette()
                    Spacer()
                    rightPalette()
                }
                .padding([.leading, .trailing], 10)
            }
            .ignoresSafeArea(.all, edges: [.top, .trailing, .leading])
        }
        .background(Color(SKColor.gray))
    }
    
    // MARK: Palettes
    
    private func rightPalette() -> some View {
        VStack (spacing: 0) {
            debugButton
            pauseButton
            addButton
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .stroke(.opacity(0.6), lineWidth: 0.5)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
        )
    }
    
    private func leftPalette() -> some View {
        VStack (spacing: 0) {
            CustomToggleSwitch(
                isToggled: $isCameraLocked,
                iconOn: Image("frame-icon"),
                labelOn: "Camera Unlocked",
                iconOff: Image("frame-icon"),
                labelOff: "Camera Locked",
                onToggle: { _ in
                    myScene.lockCamera(!isCameraLocked)
                }
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .stroke(.opacity(0.6), lineWidth: 0.5)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
        )
    }
    
    // MARK: View Buttons
    
    private var addButton: some View {
        Button(action: {
            
        }, label: {
            Image("plus-icon")
                .renderingMode(.template)
                .frame(width: 32, height: 32)
        })
        .buttonStyle(iconNoBackground())
    }
    
    private var pauseButton: some View {
        Button(action: {
            isPaused.toggle()
        }, label: {
            Image(isPaused ? "play-icon" : "pause-icon")
                .renderingMode(.template)
                .frame(width: 32, height: 32)
        })
        .buttonStyle(iconNoBackground())
    }
    
    private var settingsButton: some View {
        Button(action: {
            isSheetON = true
        }, label: {
            Image("gear-icon")
                .renderingMode(.template)
                .frame(width: 32, height: 32)
        })
        .buttonStyle(iconNoBackground())
    }
    
    private var debugButton: some View {
        Button(action: {
            if let view = myScene.view {
                isDebugON.toggle()
                myScene.toggleDebugOptions(view: view, extended: true)
            }
        }) {
            Image(isDebugON ? "chart-bar-icon" : "chart-bar-icon")
                .renderingMode(.template)
                .foregroundColor(isDebugON ? .black : .black.opacity(0.3))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(iconNoBackground())
    }
}

#Preview {
    ManipulationView()
}

// MARK: - SpriteKit

class ManipulationScene: SKScene {
    
    // MARK: didMove
    
    override func didMove(to view: SKView) {
        /// configure view
        size = view.bounds.size
        scaleMode = .resizeFill
        view.contentMode = .center
        view.isMultipleTouchEnabled = true
        backgroundColor = .gray
        
        /// physics
        cleanPhysics()
        physicsWorld.gravity = CGVector(dx: 0, dy: -20)
        
        let sprite = SKSpriteNode(color: .systemYellow, size: CGSize(width: 60, height: 60))
        addChild(sprite)
        
        /// create layers
        addChild(objectLayer)
        let gridbackground = SKSpriteNode(texture: generateGridTexture(cellSize: 75, rows: 30, cols: 30, linesColor: SKColor(white: 0, alpha: 0.3)))
        gridbackground.zPosition = -1
        objectLayer.addChild(gridbackground)
        
        /// create camera
        let inertialCamera = InertialCamera(scene: self)
        inertialCamera.lock = true
        camera = inertialCamera
        addChild(inertialCamera)
        inertialCamera.zPosition = 9999
        
        /// objects
        createDraggableSprite(view: view, parent: objectLayer)
        createSeekingSprite(view: view, parent: objectLayer)
    }
    
    var objectLayer = SKNode()
    
    func lockCamera(_ lock: Bool) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.stopInertia()
            inertialCamera.lock = lock
        }
    }
    
    // MARK: - Position Dragging
    
    func createDraggableSprite(view: SKView, parent: SKNode) {
        let sprite = DraggableSprite(texture: nil, color: .systemYellow, size: CGSize(width: 60, height: 60))
        parent.addChild(sprite)
        
        let label = SKLabelNode(text: "Position Dragging")
        label.numberOfLines = 2
        label.preferredMaxLayoutWidth = 60
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.fontColor = SKColor(white: 0, alpha: 0.6)
        label.fontSize = 14
        label.fontName = "SF-Pro"
        sprite.addChild(label)
    }
    
    // MARK: - GameplayKit
    
    func createSeekingSprite(view: SKView, parent: SKNode) {

    }
    
    override func update(_ currentTime: TimeInterval) {
        if let inertialCamera = camera as? InertialCamera {
            inertialCamera.updateInertia()
        }
        
    }
}

/**
 
 ## Physics based object manipulation
 
 - Regional, or per node
 - Direct velocity change, or force/impulse application
 
 */
