/**
 
 # Core Image filters in SpriteKit
 
 We can use Core Image filters to apply post-processing effects in SpriteKit.
 Filters can be applied to any node of type `SKEffectNode` using the `filter` property.
 A SpriteKit scene is itself of type SKEffectNode. Therefore filters can be applied to it, provided we enable filtering, which is disabled by default (see the `didMove` method below).
 One or many nodes can be made children of an SKEffectNode in order to receive filters.
 
 The base syntax for applying a filter is: `myEffectNode.filter = CIFilter(name: "CIGaussianBlur")`
 SpriteKit's API expect only one filter can be applied at a time
 
 ## Tips
 
 - If you add a node to an SKEffectNode parent node, make sure you do not add it as a child of the scene or another parent.
 - Set `shouldEnableEffects` to `true` for the scene before applying a CIFilter. By default, `shouldEnableEffects` is set to false for the scene.
 - Some Core Image filters take an inputCenter parameter of type `CIVector`. `shouldCenterFilter` is supposed to use the center of the node as input center for the filer. In my experiments, it doesn't work. It is set to true by default
 - Filters are only applied to nodes of type SKEffectNode.
 - The result of a Core Image filter may produce an image that exceeds Metal's maxium texture size (8192x8192 or 16384x16384, depending on the GPU). To avoid a crash, we need to access the processing Core Image does before it is sent back to SpriteKit's renderer. One solution is to write a custom version of the `CIFilter` method. See `ChainCIFilter` in Utilities.
 
 ## Usage
 
 Use the `ChainCIFilter` custom method in order to:
 - Chain multiple filters
 - Prevent Metal from crashing if a filter produces an image larger than Metal's texture size limit
 - Syntax:
 
 ```
 myEffectNode.filter = ChainCIFilter(filters: [
    CIFilter(name: "CIMotionBlur", parameters: ["inputRadius": 30, "inputAngle": 0])
 ])
 ```
 
 ## Links
 
 - Apple Documentation, SpriteKit Filter: https://developer.apple.com/documentation/spritekit/skeffectnode/1459392-filter
 - Core Image Reference (outdated) https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/
 - A list of CIFilter (has more filters than Apple's old reference) https://gist.github.com/Umity/c42920a236ad4fdd950492678a9136fa
 
 Created: 3 January 2024
 Updated: 8 February 2024
 
 */

import SwiftUI
import SpriteKit
import Observation
import CoreImage

// MARK: - SwiftUI view

struct CustomSliderView: View {
    let filterName: String
    let parameterName: String
    let parameterDisplayName: String
    let range: ClosedRange<CGFloat>
    let effectNode: SKEffectNode
    let updateFilterParameter: (String, String, CGFloat) -> Void
    
    @State private var sliderValue: CGFloat
    
    init(
        filterName: String,
        parameterName: String,
        parameterDisplayName: String,
        range: ClosedRange<CGFloat>,
        effectNode: SKEffectNode,
        updateFilterParameter: @escaping (String, String, CGFloat) -> Void,
        initialValue: CGFloat
    ) {
        self.filterName = filterName
        self.parameterName = parameterName
        self.parameterDisplayName = parameterDisplayName
        self.range = range
        self.effectNode = effectNode
        self.updateFilterParameter = updateFilterParameter
        self._sliderValue = State(initialValue: initialValue) // Use _ to directly initialize @State
    }
    
    var body: some View {
        HStack {
            Text(parameterDisplayName)
            Slider(
                value: $sliderValue,
                in: range,
                step: 0.01
            )
            .onChange(of: sliderValue) {
                updateFilterParameter(filterName, parameterName, sliderValue)
            }
        }
    }
}


struct ImageFilters: View {
    @State var myScene = FiltersScene()
    
    @State var selectedFilterName: String = ""
    @State var isFilterEnabled: Bool = false
    
    @State var isUIVisible: Bool = true
    @State var UIOffset: Double = 100
    
    init() {
        if let firstFilterName = myScene.filterManager.catalog.first?.name {
            /// Directly access the underlying storage of the state variable and initialize it with the name of the first filter in the catalog
            _selectedFilterName = State(initialValue: firstFilterName)
        } else {
            /// If there are no filters, initialize the state variable with an empty string or a default value.
            _selectedFilterName = State(initialValue: "")
        }
    }
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                preferredFramesPerSecond: 120,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount]
            )
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.bouncy(duration: 0.16)) {
                    isUIVisible.toggle()
                }
            }
            VStack {
                Spacer()
                
                VStack {
                    
                    /**
                     
                     For each parameter of the selected filter:
                     - If the parameter is scalar, create a slider
                        - initial value: default value from filter definition, or current value from applied filters
                        - range
                        - label with display name
                     - if the parameter is vector
                        - label with text "tap the screen to change filter center"
                     
                     */
                    
                    Toggle("", isOn: $isFilterEnabled)
                        .onChange(of: isFilterEnabled) {
                            myScene.filterManager.apply(filterName: selectedFilterName, effectNode: myScene.scene!, isEnabled: isFilterEnabled)
                        }
                    
                    HStack {
                        
                        Picker("Select a filter", selection: $selectedFilterName) {
                            ForEach(myScene.filterManager.catalog, id: \.name) { filter in
                                Text(filter.displayName).tag(filter.name)
                            }
                        }
                        .onChange(of: selectedFilterName) {
                            let filterState = (myScene.filterManager.getInfo(filterName: selectedFilterName, for: myScene.scene!)?.isEnabled as? Bool) ?? false
                            isFilterEnabled = filterState
                            myScene.filterManager.selectedFilter = selectedFilterName
                        }
                    }
                    
                    Button("Print info") {
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .foregroundStyle(.white)
                .opacity(isUIVisible ? 1.0 : 0)
                .offset(y: isUIVisible ? 0 : 50)
            }
        }
    }
}

// MARK: - Filter Manager

class FilterManager {

    // MARK: Types
    struct FilterDefinition: Hashable {
        let name: String
        let displayName: String
        let defaultParameters: [FilterParameter]?
    }
    
    struct FilterParameter: Hashable {
        let name: ParameterName
        let type: ParameterType
        let range: ClosedRange<CGFloat>?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
    }
    
    // FilterName is not used. I'll see if it's worth implementing as I go
    enum FilterName: String, CaseIterable {
        case motionBlur = "CIMotionBlur"
        case xRay = "CIXRay"
        case dither = "CIDither"
        case gaussianBlur = "CIGaussianBlur"
        case zoomBlur = "CIZoomBlur"
        case vignette = "CIVignette"
        case CMYKHalftone = "CICMYKHalftone"
        
        var displayName: String {
            switch self{
            case .motionBlur: return "Motion Blur"
            case .xRay: return "X-Ray"
            case .dither: return "Dither"
            case .gaussianBlur: return "Gaussian Blur"
            case .zoomBlur: return "Zoom Blur"
            case .vignette: return "Vignette"
            case .CMYKHalftone: return "CMYK Halftone"
            }
        }
    }
    
    enum ParameterName: String, CaseIterable {
        case inputAmount = "inputAmount"
        case inputRadius = "inputRadius"
        case inputAngle = "inputAngle"
        case inputIntensity = "inputIntensity"
        case inputCenter = "inputCenter"
        case inputWidth = "inputWidth"
        case inputSharpness = "inputSharpness"
        case inputGCR = "inputGCR"
        case inputUCR = "inputUCR"
        
        var displayName: String {
            switch self {
            case .inputAmount: return "Amount"
            case .inputRadius: return "Radius"
            case .inputAngle: return "Angle"
            case .inputIntensity: return "Intensity"
            case .inputCenter: return "Center"
            case .inputWidth: return "Width"
            case .inputSharpness: return "Sharpness"
            case .inputGCR: return "GCR"
            case .inputUCR: return "UCR"
            }
        }
    }
    
    enum ParameterType: Equatable {
        case scalar(value: CGFloat)
        case vector(value: CIVector)
        case color(value: CIColor)
    }
    
    // MARK: Curated list of Core Image filters
    let catalog: [FilterDefinition] = [
        FilterDefinition(name: "CIMotionBlur", displayName: "Motion Blur", defaultParameters: [
            FilterParameter(name: .inputRadius, type: .scalar(value: 20), range: 0...500),
            FilterParameter(name: .inputAngle, type: .scalar(value: 0), range: (-.pi)...(.pi))
        ]),
        
        FilterDefinition(name: "CIXRay", displayName: "X-Ray", defaultParameters: nil),
        
        FilterDefinition(name: "CIDither", displayName: "Dither", defaultParameters: [
            FilterParameter(name: .inputIntensity, type: .scalar(value: 0.5), range: 0...3)
        ]),
        
        FilterDefinition(name: "CIGaussianBlur", displayName: "Gaussian Blur", defaultParameters: [
            FilterParameter(name: .inputRadius, type: .scalar(value: 10), range: 0...100)
        ]),
        
        FilterDefinition(name: "CIZoomBlur", displayName: "Zoom Blur", defaultParameters: [
            FilterParameter(name: .inputAmount, type: .scalar(value: 10), range: -60...60),
            FilterParameter(name: .inputCenter, type: .vector(value: CIVector(x: 150, y: 150)), range: nil)
        ]),
        
        FilterDefinition(name: "CIVignette", displayName: "Vignette", defaultParameters: [
            FilterParameter(name: .inputIntensity, type: .scalar(value: 1), range: 0...3)
        ]),
        
        FilterDefinition(name: "CICMYKHalftone", displayName: "CMYK Halftone", defaultParameters: [
            FilterParameter(name: .inputCenter, type: .vector(value: CIVector(x: 150, y: 150)), range: nil),
            FilterParameter(name: .inputWidth, type: .scalar(value: 6), range: -2...100),
            FilterParameter(name: .inputAngle, type: .scalar(value: 0), range: (-.pi)...(.pi)),
            FilterParameter(name: .inputSharpness, type: .scalar(value: 0.7), range: 0...1),
            FilterParameter(name: .inputGCR, type: .scalar(value: 0.5), range: 0...1),
            FilterParameter(name: .inputUCR, type: .scalar(value: 0.5), range: 0...1)
        ])
    ]
    
    // MARK: State
    struct AppliedFilter {
        let name: String
        var parameters: [String: ParameterType]
        var isEnabled: Bool
    }
    
    var sceneFilters: [SKEffectNode: [AppliedFilter]] = [:] {
        didSet {
            render()
        }
    }
    
    var selectedFilter: String?
    
    // MARK: API
    
    // currently used in touchesMoved
    func getSelectedFilter() -> FilterDefinition? {
        guard let selectedFilterName = selectedFilter else { return nil }
        return catalog.first { $0.name == selectedFilterName }
    }
    // currently used in touchesMoved, should be removed and using an improved get function
    func supportsParameter(filter: FilterDefinition?, parameterName: ParameterName) -> Bool {
        guard let filter = filter else { return false }
        return filter.defaultParameters?.contains(where: { $0.name == parameterName }) ?? false
    }
    
    // MARK: -
    
    /**
     
     I want to rewrite getFilterDefinition such as:
     - I can write getFilterDefinition(filterName).defaultParameters -> returns the array of default parameters, from which I can get a count and whether or not the filter has parameters
     - I can write getFilterDefinition(filterName).defaultParameters.type -> returns all types supported (scalar, vector, color)
     - I can write getFilterDefinition(filterName).defaultParameters.type.scalar -> returns all scalar parameters
     - I can write getFilterDefinition(filterName).defaultParameters.type.vector -> returns all vector paramters
     - I can write getFilterDefinition(filterName).defaultParameters[name] -> returns the type, default value, and range of the parameter (nil if no range)
     
     Do you see what I mean? It is a kind of reverse reconstruction of the work we've done defining the filters with proper types
     
     */
    
    func getFilterDefinition(filterName: String) -> (displayName: String, hasParameters: Bool, scalarParameters: [(name: String, displayName: String, defaultValue: CGFloat, range: ClosedRange<CGFloat>?)], vectorParameters: [(name: String, displayName: String, defaultValue: CIVector)]) {
        guard let filterDefinition = catalog.first(where: { $0.name == filterName }) else {
            return ("❌ FilterManager.getFilterDefinition -  Filter not in the catalog: \(filterName)", false, [], [])
        }
        
        let hasParameters = filterDefinition.defaultParameters != nil
        var scalarParameters = [(name: String, displayName: String, defaultValue: CGFloat, range: ClosedRange<CGFloat>?)]()
        var vectorParameters = [(name: String, displayName: String, defaultValue: CIVector)]()
        
        filterDefinition.defaultParameters?.forEach { param in
            switch param.type {
            case .scalar(let value):
                scalarParameters.append((name: param.name.rawValue, displayName: param.name.displayName, defaultValue: value, range: param.range))
            case .vector(let value):
                vectorParameters.append((name: param.name.rawValue, displayName: param.name.displayName, defaultValue: value))
            default:
                // Handle other parameter types if necessary
                break
            }
        }
        
        return (filterDefinition.displayName, hasParameters, scalarParameters, vectorParameters)
    }
    
    // MARK: -
    
    func apply(filterName: String, effectNode: SKEffectNode, parameters: [ParameterName: ParameterType]? = nil, isEnabled: Bool? = nil, order: Int? = nil) {
        guard let filter = catalog.first(where: { $0.name == filterName }) else {
            print("❌ FilterManager.apply - Invalid filter name: \(filterName)"); return
        }
        /// get the array of filters added to this node. If none, create an empty array
        var associatedFilters = sceneFilters[effectNode] ?? []
        /// check if the filter already exists within the associated filters
        if let index = associatedFilters.firstIndex(where: { $0.name == filterName }) {
            /// Filter exists
            var currentFilter = associatedFilters[index]
            /// Update parameters if provided, merging new with existing ones
            parameters?.forEach { key, value in
                currentFilter.parameters[key.rawValue] = value
            }
            /// Update isEnabled if provided
            if let newIsEnabled = isEnabled {
                currentFilter.isEnabled = newIsEnabled
            }
            /// Assign the modified filter back to the array
            associatedFilters[index] = currentFilter
        } else {
            /// Create a new filter
            /// If parameters are provided, use them; otherwise, initialize with default values
            var newParameters: [String: ParameterType] = [:]
            parameters?.forEach { key, value in
                newParameters[key.rawValue] = value
            }
            /// If no parameters are provided, use default values
            if newParameters.isEmpty {
                filter.defaultParameters?.forEach { param in
                    newParameters[param.name.rawValue] = param.type
                }
            }
            let newFilter = AppliedFilter(name: filterName, parameters: newParameters, isEnabled: isEnabled ?? true)
            associatedFilters.append(newFilter)
        }
        sceneFilters[effectNode] = associatedFilters
    }
    
    // old getInfo method that I will probably remove
    func getInfo(filterName: String, for effectNode: SKEffectNode) -> AppliedFilter? {
        guard catalog.contains(where: { $0.name == filterName }) else {
            print("❌ FilterManager.getState - Invalid filter name: \(filterName)"); return nil
        }
        
        return sceneFilters[effectNode]?.first(where: { $0.name == filterName })
    }
    
    func render() {
        for (effectNode, associatedFilters) in sceneFilters {
            let ciFilters = associatedFilters.filter { $0.isEnabled }.compactMap { appliedFilter -> CIFilter? in
                guard let ciFilter = CIFilter(name: appliedFilter.name) else {
                    print("❌ FilterManager.render - Filter with name \(appliedFilter.name) is not valid \n")
                    return nil
                }
                
                appliedFilter.parameters.forEach { key, value in
                    switch value {
                    case .scalar(let scalarValue):
                        ciFilter.setValue(scalarValue, forKey: key)
                    case .vector(let vectorValue):
                        ciFilter.setValue(vectorValue, forKey: key)
                    case .color(let colorValue):
                        ciFilter.setValue(colorValue, forKey: key)
                    }
                }
                return ciFilter
            }
            
            effectNode.filter = ChainCIFilter(filters: ciFilters)
        }
    }

}

// MARK: - SpriteKit

@Observable class FiltersScene: SKScene {
    
    var filterManager = FilterManager()
    
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
        
        let scalarParam = ["inputAmount": 10]
        let vectorParam = ["inputCenter": CIVector(x: 1000, y: 1000)]
        // Merge the scalar and vector parameters into a single dictionary
        var combinedParams: [String: Any] = [:]
        combinedParams.merge(scalarParam) { (current, _) in current }
        combinedParams.merge(vectorParam) { (current, _) in current }
        
        setupPhysicsBoundaries()
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
        sprite02.physicsBody = SKPhysicsBody(texture: texture02, size: texture02.size())
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
        
        let rainTexture = SKTexture(imageNamed: "basketball-94")
        let emitterNode = SKEmitterNode()
        emitterNode.particleTexture = rainTexture
        emitterNode.particleBirthRate = 80.0
        emitterNode.particleColor = SKColor.white
        emitterNode.particleSpeed = -450
        emitterNode.particleSpeedRange = 150
        emitterNode.particleLifetime = 2.0
        emitterNode.particleScale = 0.2
        emitterNode.particleScaleRange = 0.5
        emitterNode.particleAlpha = 0.75
        emitterNode.particleAlphaRange = 0.5
        emitterNode.position = CGPoint.zero
        emitterNode.particlePositionRange = CGVector(dx: 1000, dy: 300)
        
        let effectNode = SKEffectNode()
        effectNode.zPosition = 10
        effectNode.addChild(emitterNode)
        addChild(effectNode)
        //addChild(emitterNode)
    }
    
    // MARK: Touch
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            
            let touchLocation = t.location(in: view)
            
            /// Used to define a value for the inputCenter parameter of some CI filters
            let inputCenter = CIVector(
                x: touchLocation.x * 2,
                y: -touchLocation.y * 2 + (size.height * 2)
            )
            
            if let filter = filterManager.getSelectedFilter(),
               filterManager.supportsParameter(filter: filter, parameterName: .inputCenter) {
                let parameters: [FilterManager.ParameterName: FilterManager.ParameterType] = [.inputCenter: .vector(value: inputCenter)]
                filterManager.apply(filterName: filter.name, effectNode: scene!, parameters: parameters)
            }
        }
    }
    
}

#Preview {
    ImageFilters()
}

let filtersListArchive = [
    CIFilter(name: "CIBoxBlur", parameters: ["inputRadius": 10]),
    CIFilter(name: "CIVignette", parameters: ["inputRadius": 1, "inputIntensity": 10]),
    CIFilter(name: "CIBloom", parameters: ["inputRadius": 10, "inputIntensity": 10]),
    CIFilter(name: "CIColorClamp", parameters: ["inputMinComponents": CIVector(x: 0, y: 0, z: 0, w: 0), "inputMaxComponents": CIVector(x: 1, y: 1, z: 10, w: 1)]),
    CIFilter(name: "CIColorControls", parameters: ["inputSaturation": 1, "inputBrightness": 10, "inputContrast": 1]),
    CIFilter(name: "CIExposureAdjust", parameters: ["inputEV": 10]),
    CIFilter(name: "CIGammaAdjust", parameters: ["inputPower": 10]),
    CIFilter(name: "CIHueAdjust", parameters: ["inputAngle": 10]),
    CIFilter(name: "CIVibrance", parameters: ["inputAmount": 10]),
    CIFilter(name: "CIWhitePointAdjust", parameters: ["inputColor": CIColor(red: 10, green: 1, blue: 1, alpha: 1)]),
    CIFilter(name: "CIColorInvert"),
    CIFilter(name: "CIColorMonochrome", parameters: ["inputColor": CIColor(red: 0, green: 0, blue: 0, alpha: 1), "inputIntensity": 10]),
    CIFilter(name: "CICircularScreen", parameters: ["inputCenter": CIVector(x: 300, y: 300), "inputWidth": 10, "inputSharpness": 1]),
    CIFilter(name: "CIDocumentEnhancer", parameters: ["inputAmount": 10]),
    CIFilter(name: "CIThermal"),
    
    CIFilter(name: "CICircularWrap", parameters: [
        "inputCenter": CIVector(x: 1070, y: 1070),
        "inputRadius": 10,
        "inputAngle": 6.28
    ]),
    
    CIFilter(name: "CIDotScreen", parameters: [
        "inputCenter": CIVector(x: 512, y: 512),
        "inputAngle": 0,
        "inputWidth": 10,
        "inputSharpness": 1
    ]),
    
    CIFilter(name: "CIMorphologyRectangleMaximum", parameters: [
        "inputWidth": 10,
        "inputHeight": 0
    ]),
    
    CIFilter(name: "CIMorphologyMinimum", parameters: [
        "inputRadius": 10
    ]),
    
    CIFilter(name: "CIMorphologyMaximum", parameters: [
        "inputRadius": 10
    ]),
    
    CIFilter(name: "CIMorphologyGradient", parameters: [
        "inputRadius": 1
    ]),
    
    CIFilter(name: "CIHexagonalPixellate", parameters: [
        "inputCenter": CIVector(x: 1000, y: 1000),
        "inputScale": 10
    ]),
    
    CIFilter(name: "CICrystallize", parameters: ["inputRadius": 10]),
    CIFilter(name: "CISepiaTone", parameters: ["inputIntensity": 10]),
    CIFilter(name: "CIBumpDistortion"),
    CIFilter(name: "CISpotLight"),
    CIFilter(name: "CIPointillize"),
    CIFilter(name: "CIKaleidoscope", parameters: ["inputCount": 10]),
    CIFilter(name: "CIPhotoEffectFade"),
]
