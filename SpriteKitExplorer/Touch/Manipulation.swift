//
//  Manipulation.swift
//  SpriteKitExplorer
//
//  Created by Achraf Kassioui on 6/5/2024.
//

import SwiftUI
import SpriteKit

// MARK: - SwiftUI

struct ManipulationView: View {
    @State private var sceneId = UUID()
    @State var isPaused: Bool = false
    var scene = PhysicsPlaygroundScene()
    
    var body: some View {
        VStack(spacing: 0) {
            SpriteView(
                scene: scene,
                options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes]
                //debugOptions: [.showsPhysics]
            )
            /// force recreation using the unique ID
            .id(sceneId)
            .onAppear {
                /// generate a new ID on each appearance
                sceneId = UUID()
            }
            .ignoresSafeArea(.all, edges: [.top, .trailing, .leading])
            menuBar()
        }
        .background(Color(red: 0.89, green: 0.89, blue: 0.84))
    }
    
    private func menuBar() -> some View {
        HStack {
            Spacer()
            playPauseButton
            Spacer()
        }
        .padding([.top, .leading, .trailing], 10)
        .background(.regularMaterial)
    }
    
    private var playPauseButton: some View {
        Button(action: {
            scene.isPaused.toggle()
            isPaused.toggle()
        }) {
            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
        }
        .frame(width: 60, height: 60)
        .background(Color.white.opacity(0.5))
        .clipShape(Circle())
        .overlay(Circle().stroke(.black, lineWidth: 1))
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
        backgroundColor = SKColor(red: 0.89, green: 0.89, blue: 0.84, alpha: 1)
        
        /// physics
        cleanPhysics()
        physicsWorld.gravity = CGVector(dx: 0, dy: -20)
        physicsWorld.speed = 1
        
        /// action speed
        speed = 1
        
        /// physics simulation and actions ON/OFF toggle
        isPaused = false
        
        /// create background
        let gridbackground = SKSpriteNode(texture: generateGridTexture(cellSize: 150, rows: 10, cols: 10, linesColor: SKColor(white: 0, alpha: 0.1)))
        gridbackground.zPosition = -1
        addChild(gridbackground)
        
        /// create camera
        let inertialCamera = InertialCamera(scene: self)
        camera = inertialCamera
        addChild(inertialCamera)
        inertialCamera.zPosition = 9999
        inertialCamera.lock = true
        
        ///
    }
}

/**
 
 ## Physics based object manipulation
 
 - Regional, or per node
 - Direct velocity change, or force/impulse application
 
 */
