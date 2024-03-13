/**
 
 # Core Image filters for SpriteKit and SwiftUI
 
 Wrapping Core Image filters inside a data model and API to make them easier to use in SpriteKit
 Work in progress.
 
 Created: 3 January 2024
 Updated: 22 February 2024
 
 */

import SwiftUI
import SpriteKit
import Observation

// MARK: - SwiftUI view

struct ImageFilters: View {
    var myScene = FiltersScene()
    
    @State var isFilterEnabled: Bool = true
    @State var sliderValue: CGFloat = 0
    
    var body: some View {
        ZStack {
            // MARK: SpriteView
            SpriteView(
                scene: myScene,
                preferredFramesPerSecond: 120,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount]
            )
            .ignoresSafeArea()
            
            // MARK: Filter UI
            VStack {
                Spacer()
                if isFilterEnabled {
                    Slider(
                        value: $sliderValue,
                        in: -10...10,
                        step: 0.1,
                        label: {
                            Text("Parameter Display Name")
                        },
                        minimumValueLabel: {
                            Text("-10")
                        },
                        maximumValueLabel: {
                            Text("10")
                        }
                    )
                }
                
                Toggle(isOn: $isFilterEnabled, label: {
                    Text(isFilterEnabled ? "Filter is ON" : "Filter is OFF")
                        .frame(width: 100)
                })
                .fixedSize()
            }
            .padding()
        }
    }

}

// MARK: - Filter view model

class FilterViewModel: ObservableObject {
    
    @Published var appliedFilters: [AppliedFilter] = []
    let defaultFilter = FilterModel.FilterName.motionBlur
    
    struct AppliedFilter: Hashable {
        var definition: FilterModel.FilterDefinition
        var targetNode: SKEffectNode
        var currentParameters: [FilterModel.ParameterName: FilterModel.ParameterValue]
        var isActive: Bool
    }
    
    // MARK: API
    static func toggle(filterName: FilterModel.FilterName, targetNode: SKEffectNode, isActive: Bool) {
        // look for filter + node combo in the applied filters list
        // if it's not there, add the filter + node combo to the list
        // set the isActive property accordingly
        // if isActive is true, construct a CIFilter from the filter
        //
    }
    
}

// MARK: - Filter model

struct FilterModel {
    
    // MARK: Definition
    struct FilterDefinition: Hashable, Codable {
        let filterName: FilterName
        let filterParameters: [ParameterName: ParameterValue]?
        
        /// This is added to conform to Hashable protocol
//        func hash(into hasher: inout Hasher) {
//            hasher.combine(filterName)
//        }
        
        /// Convenience method. Get the names of the supported parameter names of a given filter
        var parameterNames: [String] {
            filterParameters?.keys.map { $0.ciName } ?? []
        }
    }
    
    enum FilterName: String, Hashable, CaseIterable, Codable {
        case motionBlur = "CIMotionBlur"
        case gaussianBlur = "CIGaussianBlur"
        case zoomBlur = "CIZoomBlur"
        case CMYKHalftone = "CICMYKHalftone"
        case dither = "CIDither"
        case xRay = "CIXRay"
        case vignette = "CIVignette"
        case monochrome = "CIColorMonochrome"
        
        var ciName: String {
            return self.rawValue
        }
        
        var displayName: String {
            switch self{
            case .motionBlur: return "Motion Blur"
            case .gaussianBlur: return "Gaussian Blur"
            case .zoomBlur: return "Zoom Blur"
            case .CMYKHalftone: return "CMYK Halftone"
            case .dither: return "Dither"
            case .xRay: return "X-Ray"
            case .vignette: return "Vignette"
            case .monochrome: return "Monochrome"
            }
        }
    }
    
    enum ParameterName: String, Hashable, Codable {
        case inputAmount = "inputAmount"
        case inputRadius = "inputRadius"
        case inputAngle = "inputAngle"
        case inputIntensity = "inputIntensity"
        case inputCenter = "inputCenter"
        case inputWidth = "inputWidth"
        case inputSharpness = "inputSharpness"
        case inputColor = "inputColor"
        
        var ciName: String {
            return self.rawValue
        }
        
        var displayName: String {
            switch self {
            case .inputAmount: return "Amount"
            case .inputRadius: return "Radius"
            case .inputAngle: return "Angle"
            case .inputIntensity: return "Intensity"
            case .inputCenter: return "Center"
            case .inputWidth: return "Width"
            case .inputSharpness: return "Sharpness"
            case .inputColor: return "Color"
            }
        }
    }
    
    enum ParameterValue: Hashable, Codable {
        case scalar(defaultValue: CGFloat, lowerBound: CGFloat, upperBound: CGFloat)
        case twoDimensional(x: CGFloat, y: CGFloat)
        case fourDimensional(x: CGFloat, y: CGFloat, z: CGFloat, w: CGFloat)
        case color(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
        
        var isScalar: Bool {
            if case .scalar = self { return true }
            return false
        }
        
        var isTwoDimensional: Bool {
            if case .twoDimensional = self { return true }
            return false
        }
        
        var isFourDimensional: Bool {
            if case .fourDimensional = self { return true }
            return false
        }
        
        var isColor: Bool {
            if case .color = self { return true }
            return false
        }
        
        var scalarValues: (defaultValue: CGFloat, lowerBound: CGFloat, upperBound: CGFloat)? {
            guard case let .scalar(defaultValue, lowerBound, upperBound) = self else { return nil }
            return (defaultValue, lowerBound, upperBound)
        }
        
        var twoDimensionalValues: (x: CGFloat, y: CGFloat)? {
            guard case let .twoDimensional(x, y) = self else { return nil }
            return (x, y)
        }
        
        var fourDimensionalValues: (x: CGFloat, y: CGFloat, z: CGFloat, w: CGFloat)? {
            guard case let .fourDimensional(x, y, z, w) = self else { return nil }
            return (x, y, z, w)
        }
        
        var colorValues: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
            guard case let .color(red, green, blue, alpha) = self else { return nil }
            return (red, green, blue, alpha)
        }
    }

    // MARK: list
    let list: [FilterDefinition] = [
        FilterDefinition(filterName: .motionBlur, filterParameters: [
            .inputRadius: .scalar(defaultValue: 20, lowerBound: 0, upperBound: 50),
            .inputAngle: .scalar(defaultValue: 0, lowerBound: -.pi, upperBound: .pi)
        ]),
        FilterDefinition(filterName: .gaussianBlur, filterParameters: [
            .inputRadius: .scalar(defaultValue: 10, lowerBound: 0, upperBound: 100)
        ]),
        FilterDefinition(filterName: .zoomBlur, filterParameters: [
            .inputAmount: .scalar(defaultValue: 10, lowerBound: -60, upperBound: 60),
            .inputCenter: .twoDimensional(x: 150, y: 150)
        ]),
        FilterDefinition(filterName: .CMYKHalftone, filterParameters: [
            .inputWidth: .scalar(defaultValue: 6, lowerBound: -2, upperBound: 100),
            .inputAngle: .scalar(defaultValue: 0, lowerBound: -.pi, upperBound: .pi),
            .inputSharpness: .scalar(defaultValue: 0.7, lowerBound: 0, upperBound: 1),
        ]),
        FilterDefinition(filterName: .dither, filterParameters: [
            .inputIntensity: .scalar(defaultValue: 0.2, lowerBound: 0, upperBound: 2)
        ]),
        FilterDefinition(filterName: .xRay, filterParameters: nil),
        FilterDefinition(filterName: .vignette, filterParameters: [
            .inputIntensity: .scalar(defaultValue: 1, lowerBound: 0, upperBound: 5)
        ]),
        FilterDefinition(filterName: .monochrome, filterParameters: [
            .inputIntensity: .scalar(defaultValue: 1, lowerBound: -10, upperBound: 10),
            .inputColor: .color(red: 0.6, green: 0.45, blue: 0.3, alpha: 1)
        ])
    ]
}

// MARK: - SpriteKit

@Observable class FiltersScene: SKScene {
    
    var selectedNode: SKEffectNode?
    
    // MARK: scene setup
    
    override func sceneDidLoad() {
        createObjects()
    }
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .black
        shouldEnableEffects = true
        shouldCenterFilter = true
        setupPhysicsBoundaries()
        if scene != nil {
            selectedNode = scene
        }
        
        /*
        filter = CIFilter(name: "CISpotLight", parameters: [
            "inputLightPosition": CIVector(x: 800.0, y: 900.0, z: 380),
            "inputLightPointsAt": CIVector(x: 200.0, y: 400.0, z: 900),
            "inputBrightness": 1,
            "inputConcentration": 1.2,
            "inputColor": CIColor(red: 1, green: 1, blue: 1)
        ])
         */
        /*
        filter = ChainCIFilter(filters: [
            CIFilter(name: "CIDither", parameters: ["inputIntensity": 1]),
            CIFilter(name: "CIMotionBlur", parameters: ["inputRadius": 20])
        ])
         */
    }
    
    func setupPhysicsBoundaries() {
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        borderBody.friction = 0
        borderBody.restitution = 1
        self.physicsBody = borderBody
    }
    
    // MARK: scene objects
    
    func createObjects() {
        let sprite01 = SKSpriteNode(imageNamed: "abstract-dunes-1024")
        sprite01.zPosition = 1
        sprite01.setScale(2.2)
        addChild(sprite01)
        
        let texture02 = SKTexture(imageNamed: "balloon-9-1024")
        let sprite02 = SKSpriteNode(texture: texture02)
        sprite02.zPosition = 2
        sprite02.position = CGPoint(x: -100, y: 270)
        //sprite02.physicsBody = SKPhysicsBody(texture: texture02, size: texture02.size())
        sprite02.physicsBody?.restitution = 1
        sprite02.setScale(0.5)
        addChild(sprite02)
        
        let instructionsText = SKLabelNode(text: "Pick a filter and experiment")
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
    
}

#Preview {
    ImageFilters()
}
