/**
 
 # ChainCIFilter.swift
 
 In Apple SpriteKit, you can use Core Image filters to add effects to any node of type `SKEffectNode`, including the scene itself.
 But by default, an SKEffectNode only takes one filter. Moreover, the output from a filter can crash SpriteKit's Metal renderer if it exceeds a size limit.
 
 This custom `CIFilter` sub-class provides a solution for both of those concerns:
 - Run multiple filters on the same effect node
 - Check the size of the output image of a filter, and only send it to SpriteKit if it does not exceed Metal's texture size limit of the host device
 
 Based on code from "zekel":  https://stackoverflow.com/questions/55553869/on-ios-can-you-add-multiple-cifilters-to-a-spritekit-node?noredirect=1&lq=1
 
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
 
 Author: Achraf Kassioui https://www.achrafkassioui.com
 Created: 4 January 2024
 Updated: 3 February 2024
 
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
