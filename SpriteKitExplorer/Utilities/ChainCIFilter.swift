/**
 
 # ChainCIFilter.swift
 
 In Apple SpriteKit, you can use Core Image filters to add effects to nodes of type `SKEffectNode`, including the scene itself.
 However, the built-in SpriteKit API only takes one filter at a time, and the output can crash SpriteKit's renderer if the result exceeds Metal texture size limit.
 
 This custom `CIFilter` sub-class provides a solution for both issues:
 - You can run multiple filters on the same effect node.
 - The size of the generated output is checked against a size limit, and is sent to SpriteKit only if the limit is not exceeded.
 
 ## Usage
 
 Long form usage in SpriteKit:
 
 ```
 let myFilters: [CIFilter] = [
    CIFilter(name: "CIZoomBlur", parameters: ["inputAmount": 20]),
    CIFilter(name: "CIPixellate", parameters: ["inputScale": 8])
 ]
 
 let appliedFilters = ChainCIFilter(filters: myFilters)
 
 myEffectNode.filter = appliedFilters
 ```
 
 Short form usage in SpriteKit:
 
 ```
 myEffectNode.filter = ChainCIFilter(filters: [
    CIFilter(name: "CIDither", parameters: ["inputIntensity": 0.6])
 ])
 ```
 
 Retrieve the array of the applied filters:
 
 ```
 if let chainFilter = myEffectNode.filter as? ChainCIFilter {
    let appliedFilters = chainFilter.chainedFilters
 }
 ```
 ## Credit
 
 Based on code from "zekel":  https://stackoverflow.com/questions/55553869/on-ios-can-you-add-multiple-cifilters-to-a-spritekit-node?noredirect=1&lq=1
 
 Author: Achraf Kassioui
 Created: 4 January 2024
 Updated: 22 February 2024
 
 */

import CoreImage

/// The code assumes there is always a Metal device
let currentDevice = MTLCreateSystemDefaultDevice()!

/// Get the Metal texture size limit depending on the GPU family of the device
/// Could be improved by not using hard coded values. But how?
func getTextureSizeLimit(metalDevice: MTLDevice) -> Int {
    /// https://developer.apple.com/documentation/metal/mtldevice/3143473-supportsfamily
    let maxTexSize = metalDevice.supportsFamily(.apple3) ? 16384 : 8192
    return maxTexSize
}

class ChainCIFilter: CIFilter {
    /// Use this variable to access the array of the filters applied
    private(set) var chainedFilters: [CIFilter]
    
    //let currentDevice: MTLDevice
    let textureSizeLimit: CGFloat
    @objc dynamic var inputImage: CIImage?
    
    init(filters: [CIFilter?]) {
        /// The array of filters can contain a nil if the CIFilter inside it is given a wrong name or parameter
        /// `compactMap { $0 }` filter out any `nil` values from the array
        self.chainedFilters = filters.compactMap { $0 }
        self.textureSizeLimit = CGFloat(getTextureSizeLimit(metalDevice: currentDevice))
        super.init()
    }
    
    /// Override `outputImage` to:
    /// - Chain multiple filters
    /// - Check the output result of each filter before it is passed on
    override var outputImage: CIImage? {
        get {
            let imageKey = "inputImage"
            var workingImage = self.inputImage
            for filter in chainedFilters {
                assert(filter.inputKeys.contains(imageKey))
                filter.setValue(workingImage, forKey: imageKey)
                guard let result = filter.outputImage else {
                    assertionFailure("Filter failed: \(filter.name)")
                    return nil
                }
                
                /// Start Metal limit test
                /// We check the `extent` property of the working image, which is a `CIImage`
                /// A CIImage is an object that represents an image but is not rendered until explicitly asked to
                
                if (result.extent.size.width > textureSizeLimit || result.extent.size.height > textureSizeLimit) {
                    print("ChainCIFilter.swift > Metal Texture Size Limit exceeded: \(result.extent.size)")
                    /// if the limit is exceeded, return the unmodified input image
                    return workingImage
                }
                /// End Metal limit test
                
                workingImage = result
            }
            /// Here the output image is passed on, ultimately to be rendered in SpriteKit or elsewhere
            return workingImage
        }
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
