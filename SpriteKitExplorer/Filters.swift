/**
 
 # Image filters in SpriteKit
 
 We can use Core Image filters to apply post-processing effects to the scene or to individual nodes.
 Filters can be applied to any node of type `SKEffectNode` using its `filter` property.
 One or many nodes can be made children of an SKEffectNode and receive filters.
 A SpriteKit scene is itself of type SKEffectNode, and therefore filters can be applied to it, provided we enable filtering, which is disabled by default.
 A filter is applied like so: `myEffectNode.filter = CIFilter(name: "CIGaussianBlur")`
 SpriteKit's API expect Only one filter can be applied at a time
 
 Tips:
 - If you add a node to an SKEffectNode parent, make sure you do not add it as a child of the scene or another parent.
 - Filters are applied to the SKEffectNode, not any node.
 - The result of a Core Image filter may produce an image that exceeds Metal's maxium texture size (8192x8192 or 16384x16384, depending on the GPU). To avoid a crash, we need to access the processing Core Image does before it is sent back to SpriteKit's renderer. One solution is to write a custom version of the `CIFilter` method that
 
 Links:
 - Apple Documentation, Filter: https://developer.apple.com/documentation/spritekit/skeffectnode/1459392-filter
 
 Created: 3 January 2024
 Updated: 28 January 2024
 
 */

import SwiftUI
import SpriteKit
import Observation
import CoreImage

// MARK: - SwiftUI view

struct Filters: View {
    @State var myScene = FiltersScene()
    
    @State private var selection = "Zoom Blur"
    let filters = [ "Zoom Blur", "Gaussian Blur", "Motion Blur", "Dither", "CMYK Halftone", "XRay"]
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount]
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Slider(
                    value: $myScene.sliderValue,
                    in: -60...60, // the range depends on the filter. I want specific range for each filter
                    step: 0.1 // same as range
                )
                .onChange(of: myScene.sliderValue) {
                    myScene.applyImageFilters()
                }
                
                Picker("Select a filter", selection: $selection) {
                    ForEach(filters, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding()
        }
    }
}

// MARK: - SpriteKit class

@Observable class FiltersScene: SKScene {
    
    var mySprite: SKSpriteNode!
    var myEffectNode: SKEffectNode!
    var sliderValue: Double = 0
    var effectCenter = CIVector(x: 0, y: 0)
    
    // MARK: scene setup
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        effectCenter = CIVector(x: size.width, y: size.height)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .black
        
        createObjects()
        
        /// SKScene is itself of type SKEffectNode. Therefore, Core Image filters can be applied to it.
        /// By default, `shouldEnableEffects` is set to false
        /// Set it to true before applying a filter
        shouldEnableEffects = true
        
        /// Use the `ChainCIFilter` custom method in order to:
        /// - Chain multiple filters
        /// - Prevent Metal from crashing if a filter produces an image larger than Metal's texture size limit
        filter = ChainCIFilter(filters: [
            /// apply a CIFilter here
        ])
        
        shouldCenterFilter = true
    }
    
    // MARK: scene objects
    
    func createObjects() {
        let sprite01 = SKSpriteNode(imageNamed: "abstract-dunes-1024")
        sprite01.position.y = -230
        sprite01.zPosition = 3
        addChild(sprite01)
        
        let sprite02 = SKSpriteNode(imageNamed: "cartoon-landscape-1024")
        sprite02.position = CGPoint(x: 0, y: 200)
        sprite02.zPosition = 4
        addChild(sprite02)
        
        let sprite03 = SKSpriteNode(imageNamed: "space-1024")
        sprite03.zPosition = 5
        sprite03.setScale(3)
        addChild(sprite03)
        
        let instructionsText = SKLabelNode(text: "Pick a filter and change the slider value")
        instructionsText.position = CGPoint(x: 0, y: 0)
        instructionsText.zPosition = 100
        instructionsText.preferredMaxLayoutWidth = 360
        instructionsText.numberOfLines = 0
        instructionsText.horizontalAlignmentMode = .center
        instructionsText.fontName = "Menlo-Bold"
        instructionsText.fontSize = 24
        instructionsText.fontColor = SKColor(white: 1, alpha: 0.5)
        addChild(instructionsText)
    }
    
    // MARK: API
    
    func animateFilter(_ anEffectNode: SKEffectNode) {
        let animationDuration = 3.0
        let myCustomAction = SKAction.customAction(withDuration: animationDuration) { node, elapsedTime in
            let dynamicValue = 2 / elapsedTime
            anEffectNode.filter = ChainCIFilter(filters: [
                CIFilter(name: "CIMotionBlur", parameters: ["inputRadius": dynamicValue])
            ])
        }
        let repeatAction = SKAction.repeatForever(myCustomAction)
        anEffectNode.run(repeatAction)
    }
    
    // MARK: Filters
    
    func applyImageFilters() {
        self.filter = ChainCIFilter(filters: [
            //CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": sliderValue]),
            //CIFilter(name: "CIMotionBlur", parameters: ["inputRadius": sliderValue, "inputAngle": 0]),
            CIFilter(name: "CIZoomBlur", parameters: ["inputCenter": effectCenter, "inputAmount": sliderValue])
            //CIFilter(name: "CIBoxBlur", parameters: ["inputRadius": sliderValue]),
            //CIFilter(name: "CIVignette", parameters: ["inputRadius": 1, "inputIntensity": sliderValue]),
            //CIFilter(name: "CIBloom", parameters: ["inputRadius": 10, "inputIntensity": sliderValue]),
            //CIFilter(name: "CIColorClamp", parameters: ["inputMinComponents": CIVector(x: 0, y: 0, z: 0, w: 0), "inputMaxComponents": CIVector(x: 1, y: 1, z: sliderValue, w: 1)]),
            //CIFilter(name: "CIColorControls", parameters: ["inputSaturation": 1, "inputBrightness": sliderValue, "inputContrast": 1]),
            //CIFilter(name: "CIExposureAdjust", parameters: ["inputEV": sliderValue]),
            //CIFilter(name: "CIGammaAdjust", parameters: ["inputPower": sliderValue]),
            //CIFilter(name: "CIHueAdjust", parameters: ["inputAngle": sliderValue]),
            //CIFilter(name: "CIVibrance", parameters: ["inputAmount": sliderValue]),
            //CIFilter(name: "CIWhitePointAdjust", parameters: ["inputColor": CIColor(red: sliderValue, green: 1, blue: 1, alpha: 1)]),
            //CIFilter(name: "CIColorInvert"),
            //CIFilter(name: "CIColorMonochrome", parameters: ["inputColor": CIColor(red: 0, green: 0, blue: 0, alpha: 1), "inputIntensity": sliderValue]),
            //CIFilter(name: "CIXRay"),
            //CIFilter(name: "CICircularScreen", parameters: ["inputCenter": effectCenter, "inputWidth": sliderValue, "inputSharpness": 1]),
            
            /*
             CIFilter(name: "CICMYKHalftone", parameters: [
             "inputCenter": CIVector(x: 150, y: 150),
             "inputWidth": 6,
             "inputAngle": 0,
             "inputSharpness": 0.7,
             "inputGCR": 1,
             "inputUCR": 0.5
             ]),
             */
            
            //CIFilter(name: "CIDither", parameters: ["inputIntensity": filterInput1]),
            //CIFilter(name: "CIDocumentEnhancer", parameters: ["inputAmount": filterInput1]),
            //CIFilter(name: "CIThermal"),
            //CIFilter(name: "CIVignette"),
            
            /*
             CIFilter(name: "CICircularWrap", parameters: [
             "inputCenter": CIVector(x: 1070, y: 1070),
             "inputRadius": sliderValue,
             "inputAngle": 6.28
             ]),
             */
            
            /*
             CIFilter(name: "CIDotScreen", parameters: [
             "inputCenter": CIVector(x: 512, y: 512),
             "inputAngle": 0,
             "inputWidth": sliderValue,
             "inputSharpness": 1
             ]),
             */
            
            /*
             CIFilter(name: "CIMorphologyRectangleMaximum", parameters: [
             "inputWidth": sliderValue,
             "inputHeight": 0
             ]),
             */
            
            /*
             CIFilter(name: "CIMorphologyMinimum", parameters: [
             "inputRadius": sliderValue
             ]),
             */
            
            /*
             CIFilter(name: "CIMorphologyMaximum", parameters: [
                "inputRadius": sliderValue
             ]),
             */
            
            /*
             CIFilter(name: "CIMorphologyGradient", parameters: [
             "inputRadius": 1
             ]),
             */
            
            /*
            CIFilter(name: "CIHexagonalPixellate", parameters: [
                //"inputCenter": CIVector(x: 1000, y: 1000),
                "inputScale": sliderValue
            ]),
             */
            
            //CIFilter(name: "CICrystallize", parameters: ["inputRadius": sliderValue]),
            
            //CIFilter(name: "CISepiaTone", parameters: ["inputIntensity": sliderValue]),
            //CIFilter(name: "CIBumpDistortion"),
            //CIFilter(name: "CIBloom"),
            //CIFilter(name: "CISpotLight"),
            //CIFilter(name: "CIPointillize"),
            //CIFilter(name: "CIKaleidoscope", parameters: ["inputCount": sliderValue]),
            //CIFilter(name: "CIPhotoEffectFade"),
        ])
    }
    
    // MARK: Touch
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let touchLocation = t.location(in: view)
            effectCenter = CIVector(
                x: touchLocation.x * 2,
                y: -touchLocation.y * 2 + (size.height * 2)
            )
            applyImageFilters()
        }
    }
}

#Preview {
    Filters()
}

