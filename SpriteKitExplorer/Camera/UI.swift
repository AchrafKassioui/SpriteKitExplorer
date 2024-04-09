/**
 
 # UI and helper methods for the camera experimentations
 
 Achraf Kassioui
 Created: 8 April 2024
 Updated: 8 April 2024
 
 */

import SpriteKit

// MARK: Button class

class ButtonWithIconAndPattern: SKShapeNode {
    
    /// a call back function to execute
    /// the function to execute is passed as an argument during initialization
    let onTouch: () -> Void
    
    private let icon: SKSpriteNode
    
    init(size: CGSize, iconName: String, iconSize: CGSize, onTouch: @escaping () -> Void) {
        self.onTouch = onTouch
        
        /// button icon
        self.icon = SKSpriteNode(imageNamed: iconName)
        self.icon.size = iconSize
        self.icon.colorBlendFactor = 1
        self.icon.color = SKColor(white: 0, alpha: 1)
        self.icon.isUserInteractionEnabled = false
        
        /// button shape
        super.init()
        self.path = CGPath(ellipseIn: CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size), transform: nil)
        
        /// styling
        let dotTexture = SKTexture(image: createDotPatternImage(size: size))
        fillTexture = dotTexture
        strokeColor = SKColor(white: 0, alpha: 1)
        fillColor = SKColor(white: 1, alpha: 0.4)
        
        isUserInteractionEnabled = true
        addChild(icon)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        onTouch()
    }
    
}

// MARK: Core Graphics pattern generator
/**
 
 Used to create background patterns to fill out UI buttons
 The generator produces a UIImage, which is used for a shape node or some other SpriteKit drawing node.
 
 */

func createDotPatternImage(size: CGSize) -> UIImage {
    let dotRadius: CGFloat = 0.5
    let spacing: CGFloat = 0.5
    let renderer = UIGraphicsImageRenderer(size: size)
    
    return renderer.image { context in
        /// if you need to set a background fill color, uncomment these 2 lines
        /// the color is set in the first line, the filling is done in the second line
        SKColor(white: 1, alpha: 1).setFill()
        context.fill(CGRect(origin: .zero, size: size))
        
        /// rotate the whole drawing
        /// the origin of the coordinate system in Core Graphics is in the top left
        /// to pivot around the center, we move the origin (the rotation pivot) to the center then put it back
        context.cgContext.translateBy(x: size.width / 2, y: size.height / 2)
        //context.cgContext.rotate(by: .pi / -4)
        context.cgContext.translateBy(x: -size.width / 2, y: -size.height / 2)
        
        /// set a color to fill the path later
        SKColor(white: 0, alpha: 1).setFill()
        
        /// the pattern
        /// a regular pattern
        /*
         for y in stride(from: 0, to: size.height, by: dotRadius * 2 + spacing) {
         for x in stride(from: 0, to: size.width, by: dotRadius * 2 + spacing) {
         let dotPath = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: dotRadius * 2, height: dotRadius * 2))
         dotPath.fill()
         }
         }
         */
        
        /// a staggered pattern
        for y in stride(from: dotRadius, to: size.height, by: dotRadius * 2 + spacing) {
            let xOffset = (y / dotRadius).truncatingRemainder(dividingBy: 2) == 0 ? 0 : dotRadius + spacing / 2
            for x in stride(from: xOffset, to: size.width, by: dotRadius * 2 + spacing) {
                let dotPath = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: dotRadius * 2, height: dotRadius * 2))
                dotPath.fill()
            }
        }
        
    }
}
