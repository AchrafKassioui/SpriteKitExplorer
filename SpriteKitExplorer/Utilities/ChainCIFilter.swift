/**
 
 # ChainCIFilter.swift
 
 By default, a SpriteKit's SKEffectNode only takes one filter at a time. And if the filter produces an image larger than Metal's texture size limit, SpriteKit renderer will crash.
 
 This custom CIFilter class allows to:
 - Run multiple filters on the same effect node
 - Check the filter result before sending it to SpriteKit renderer and thus prevent a crash if the result exceeds Metal texture size limit
 
 Based on code from "zekel":  https://stackoverflow.com/questions/55553869/on-ios-can-you-add-multiple-cifilters-to-a-spritekit-node?noredirect=1&lq=1
 
 Long form usage in SpriteKit:
 
 ```
 let myFilters: [CIFilter] = [
    CIFilter(name: "CIZoomBlur", parameters: ["inputAmount": 20]),
    CIFilter(name: "CIPixellate", parameters: ["inputScale": 8])
 ]
 
 let appliedFilters = ChainFilters(filters: myFilters)
 
 myEffectNode.filter = appliedFilters
 ```
 
 Short form usage in SpriteKit:
 
 ```
 myEffectNode.filter = CIFilter(name: "CIDither", parameters: ["inputIntensity": 0.6])
 ```
 
 Created: 4 January 2024
 Updated: 28 January 2024
 
 */

import CoreImage

/// The code assumes there is always a Metal device
let currentDevice = MTLCreateSystemDefaultDevice()!

/// Get the Metal texture size limit depending on the GPU  family of the device
/// Could be improved by not using hard coded values. But how?
func maxTextureSize(mtlDevice: MTLDevice) -> Int {
    /// https://developer.apple.com/documentation/metal/mtldevice/3143473-supportsfamily
    let maxTexSize = mtlDevice.supportsFamily(.apple3) ? 16384 : 8192
    return maxTexSize
}

class ChainCIFilter: CIFilter {
    let chainedFilters: [CIFilter]
    let textureSizeLimit: CGFloat
    @objc dynamic var inputImage: CIImage?
    
    init(filters: [CIFilter?]) {
        /// The array of filters can contain a nil if the CIFilter inside it is given a wrong name or parameter
        /// `compactMap { $0 }` filter out any `nil` values from the array
        self.chainedFilters = filters.compactMap { $0 }
        self.textureSizeLimit = CGFloat(maxTextureSize(mtlDevice: currentDevice))
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
