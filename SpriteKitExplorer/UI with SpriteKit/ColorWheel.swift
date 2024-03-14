/**
 
 # A color wheel
 
 Created: 11 March 2024
 
 */

import SpriteKit

class ColorWheel: SKNode {
    init(radius: CGFloat, position: CGPoint, hexColors: [String]) {
        super.init()
        self.position = position
        
        // Convert hex strings to UIColor, filtering out nil values
        let colors = hexColors.compactMap { UIColor(hex: $0) }
        
        // Now that we have an array of non-optional UIColors, we can proceed.
        let angle: CGFloat = 2.0 * .pi / CGFloat(colors.count)
        
        for i in 0..<colors.count {
            let color = colors[i]
            let startAngle = angle * CGFloat(i)
            let endAngle = startAngle + angle
            
            // Create a path for each section of the wheel
            let path = UIBezierPath(arcCenter: .zero, radius: radius,
                                    startAngle: startAngle, endAngle: endAngle,
                                    clockwise: true)
            path.addLine(to: .zero)
            path.close()
            
            // Create a shape node for the path
            let section = SKShapeNode(path: path.cgPath)
            section.fillColor = color
            section.strokeColor = color // Stroke color can be .clear if you don't want a border
            
            // Add the section as a child of the wheel
            addChild(section)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


