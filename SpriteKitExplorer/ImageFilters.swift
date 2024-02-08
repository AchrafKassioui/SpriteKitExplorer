/**
 
 # Core Image filters in SpriteKit
 
 We can use Core Image filters to apply post-processing effects to the rendered view or to individual nodes.
 
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
 Updated: 3 February 2024
 
 */

import SwiftUI
import SpriteKit
import Observation
import CoreImage

// MARK: - SwiftUI view

struct CustomSliderView: View {
    let filterName: String
    let parameterDisplayName: String
    let parameterName: String
    let range: ClosedRange<CGFloat>
    @Binding var sliderValue: CGFloat
    let effectNode: SKEffectNode
    let updateFilterParameter: (String, String, CGFloat) -> Void
    
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
    
    @State var selectedFilter: Int = 0
    @State var isFilterEnabled: Bool = false
    @State var filterOrder: Int = 0
    
    @State var isUIVisible: Bool = true
    @State var UIOffset: Double = 100
    
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
                    
                    ForEach(myScene.imageFilterManager.list[selectedFilter].parameters ?? [], id: \.name) { parameter in
                        if case let .scalar(defaultValue, range) = parameter.type {
                            let bindingValue = Binding<CGFloat>(
                                get: {
                                    // Fetch the current value from the sceneFilters or use the default value
                                    let currentParameter = myScene.imageFilterManager.getInfo(filterName: myScene.imageFilterManager.list[selectedFilter].name, for: myScene.scene!)?.parameters[parameter.name.rawValue] as? ImageFilterManager.ParameterType
                                    if case let .scalar(currentValue, _) = currentParameter {
                                        return currentValue
                                    } else {
                                        return defaultValue
                                    }
                                },
                                set: { newValue in
                                    myScene.imageFilterManager.apply(
                                        filterName: myScene.imageFilterManager.list[selectedFilter].name,
                                        to: myScene.scene!,
                                        parameters: [.init(rawValue: parameter.name.rawValue)!: .scalar(value: newValue, range: range)]
                                    )
                                }
                            )
                            
                            CustomSliderView(
                                filterName: myScene.imageFilterManager.list[selectedFilter].name,
                                parameterDisplayName: parameter.name.displayName,
                                parameterName: parameter.name.rawValue,
                                range: range,
                                sliderValue: bindingValue,
                                effectNode: myScene.scene!,
                                updateFilterParameter: { filterName, parameterName, newValue in
                                    myScene.imageFilterManager.apply(
                                        filterName: filterName,
                                        to: myScene.scene!,
                                        parameters: [.init(rawValue: parameterName)!: .scalar(value: newValue, range: range)]
                                    )
                                }
                            )
                        }
                    }
                    
                    HStack {
                        Toggle("", isOn: $isFilterEnabled)
                            .onChange(of: isFilterEnabled) {
                                let filterName = myScene.imageFilterManager.list[selectedFilter].name
                                let filterTarget = myScene.scene!
                                myScene.imageFilterManager.apply(filterName: filterName, to: filterTarget, isEnabled: isFilterEnabled)
                            }
                        
                        Picker("Select a filter", selection: $selectedFilter) {
                            ForEach(0..<myScene.imageFilterManager.list.count, id: \.self) {index in
                                Text(myScene.imageFilterManager.list[index].displayName).tag(index)
                            }
                        }
                        .onChange(of: selectedFilter) {
                            let filterName = myScene.imageFilterManager.list[selectedFilter].name
                            let filterTarget = myScene.scene!
                            let filterState = (myScene.imageFilterManager.getInfo(filterName: filterName, for: filterTarget)?.isEnabled as? Bool) ?? false
                            isFilterEnabled = filterState
                        }
                        
                        Picker("Order", selection: $filterOrder) {
                            ForEach(0..<myScene.imageFilterManager.list.count, id: \.self) {index in
                                Text(String(filterOrder))
                            }
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


// MARK: - Scene model

class SceneState {
    var selectedNodes: [SKNode] = []
}

// MARK: - Image Filters Model

class ImageFilterManager {

    // MARK: Filter definition
    struct Filter {
        let name: String
        let displayName: String
        let parameters: [FilterParameter]?
    }
    
    struct FilterParameter: Hashable {
        let name: FilterParameterName
        let type: ParameterType
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
    }

    enum ParameterType: Equatable {
        case scalar(value: CGFloat, range: ClosedRange<CGFloat>)
        case vector(value: CIVector)
        case color(value: CIColor)
    }
    
    enum FilterParameterName: String, CaseIterable {
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
    
    let list: [Filter] = [
        Filter(name: "CIMotionBlur", displayName: "Motion Blur", parameters: [
            FilterParameter(name: .inputRadius, type: .scalar(value: 20, range: 0...100)),
            FilterParameter(name: .inputAngle, type: .scalar(value: 0, range: (-.pi)...(.pi)))
        ]),
        
        Filter(name: "CIXRay", displayName: "X-Ray", parameters: nil),
        
        Filter(name: "CIDither", displayName: "Dither", parameters: [
            FilterParameter(name: .inputIntensity, type: .scalar(value: 0.5, range: 0...3))
        ]),
        
        Filter(name: "CIGaussianBlur", displayName: "Gaussian Blur", parameters: [
            FilterParameter(name: .inputRadius, type: .scalar(value: 10, range: 0...100))
        ]),
        
        Filter(name: "CIZoomBlur", displayName: "Zoom Blur", parameters: [
            FilterParameter(name: .inputAmount, type: .scalar(value: 10, range: -60...60)),
            FilterParameter(name: .inputCenter, type: .vector(value: CIVector(x: 150, y: 150)))
        ]),
        
        Filter(name: "CIVignette", displayName: "Vignette", parameters: [
            FilterParameter(name: .inputIntensity, type: .scalar(value: 1, range: 0...3))
        ]),
        
        Filter(name: "CICMYKHalftone", displayName: "CMYK Halftone", parameters: [
            FilterParameter(name: .inputCenter, type: .vector(value: CIVector(x: 150, y: 150))),
            FilterParameter(name: .inputWidth, type: .scalar(value: 6, range: -2...100)),
            FilterParameter(name: .inputAngle, type: .scalar(value: 0, range: (-.pi)...(.pi))),
            FilterParameter(name: .inputSharpness, type: .scalar(value: 0.7, range: 0...1)),
            FilterParameter(name: .inputGCR, type: .scalar(value: 0.5, range: 0...1)),
            FilterParameter(name: .inputUCR, type: .scalar(value: 0.5, range: 0...1))
        ])
    ]
    
    // MARK: State
    struct AddedFilter {
        let filter: Filter
        var parameters: [String: ParameterType]
        var isEnabled: Bool
    }
    
    var sceneFilters: [SKEffectNode: [AddedFilter]] = [:] {
        didSet {
            render()
        }
    }
    
    var selectedFilter: [SKEffectNode: Filter] = [:]
    
    // MARK: API
    
    func apply(filterName: String, to effectNode: SKEffectNode, parameters: [FilterParameterName: ParameterType]? = nil, isEnabled: Bool? = nil, order: Int? = nil) {
        guard let filter = list.first(where: { $0.name == filterName }) else {
            print("🚨 ImageFilterManager.apply - Invalid filter name: \(filterName)"); return
        }
        
        /// get the array of filters added to this node. If none, create an empty array
        var associatedFilters = sceneFilters[effectNode] ?? []
        
        /// check if the filter already exists within the associated filters
        if let index = associatedFilters.firstIndex(where: { $0.filter.name == filterName }) {
            /// Filter exists, update its properties
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
                filter.parameters?.forEach { param in
                    newParameters[param.name.rawValue] = param.type
                }
            }
            let newFilter = AddedFilter(filter: filter, parameters: newParameters, isEnabled: isEnabled ?? true)
            associatedFilters.append(newFilter)
        }
        
        sceneFilters[effectNode] = associatedFilters
    }
    
    func getInfo(filterName: String, for effectNode: SKEffectNode) -> AddedFilter? {
        guard list.contains(where: { $0.name == filterName }) else {
            print("🚨 ImageFilterManager.getState - Invalid filter name: \(filterName)"); return nil
        }
        
        return sceneFilters[effectNode]?.first(where: { $0.filter.name == filterName })
    }
    
    func remove(filterName: String, from effectNode: SKEffectNode) {
        guard var filters = sceneFilters[effectNode] else { return }
        filters.removeAll { $0.filter.name == filterName }
        sceneFilters[effectNode] = filters
    }
    
    func render() {
        for (effectNode, associatedFilters) in sceneFilters {
            let ciFilters = associatedFilters.filter { $0.isEnabled }.compactMap { filterInfo -> CIFilter? in
                guard let ciFilter = CIFilter(name: filterInfo.filter.name) else {
                    print("🚨 ImageFilterManager.render - Filter with name \(filterInfo.filter.name) is not valid \n")
                    return nil
                }
                
                filterInfo.parameters.forEach { key, value in
                    switch value {
                    case .scalar(let scalarValue, _):
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
    
    var sceneState = SceneState()
    var imageFilterManager = ImageFilterManager()
    var effectNode: SKEffectNode!
    
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
        
        effectNode = SKEffectNode()
        effectNode.zPosition = 10
        effectNode.addChild(emitterNode)
        addChild(effectNode)
        //addChild(emitterNode)
    }
    
    // MARK: Touch
    
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches {
//            
//            let touchLocation = t.location(in: view)
//            
//            /// Used to define a value for the inputCenter parameter of some CI filters
//            
//            let inputCenter = CIVector(
//                x: touchLocation.x * 2,
//                y: -touchLocation.y * 2 + (size.height * 2)
//            )
//        }
//    }
    
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
