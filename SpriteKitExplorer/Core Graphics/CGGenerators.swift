/**
 
 # Core Graphics Generators
 
 Methods that generate textures for use in SpriteKit
 
 Created: 18 March 2024
 Updated: 19 April 2024
 
 */

import SpriteKit

// MARK: - Dot Pattern

func generateDotPatternImage(size: CGSize) -> SKTexture {
    let dotRadius: CGFloat = 0.5
    let spacing: CGFloat = 0.5
    let renderer = UIGraphicsImageRenderer(size: size)
    
    let image = renderer.image { context in
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
    
    /// Convert the image to an SKTexture
    return SKTexture(image: image)
}

// MARK: - Shadow texture
// TODO: Fix the texture size calculation.

func generateShadowTexture(width: CGFloat, height: CGFloat, cornerRadius: CGFloat, shadowOffset: CGSize, shadowBlurRadius: CGFloat, shadowColor: SKColor) -> SKTexture {
    /// calculate the size of the texture to accommodate the shadow
    let textureSize = CGSize(
        width: width + (shadowBlurRadius * 2) + abs(shadowOffset.width),
        height: height + (shadowBlurRadius * 2) + abs(shadowOffset.height)
    )
    
    /// create a renderer with the calculated size
    let renderer = UIGraphicsImageRenderer(size: textureSize)
    
    let image = renderer.image { ctx in
        let context = ctx.cgContext
        
        /// move the origin of the rectangle to accommodate the shadow
        let rectOrigin = CGPoint(
            x: (textureSize.width - width) / 2 - shadowOffset.width,
            y: (textureSize.height - height) / 2 - shadowOffset.height
        )
        let rect = CGRect(origin: rectOrigin, size: CGSize(width: width, height: height))
        
        /// set shadow properties
        context.setShadow(offset: shadowOffset, blur: shadowBlurRadius, color: shadowColor.cgColor)
        
        /// Core Graphics needs a fill color to generate the shadows
        /// we set the fill color to white, so we can use blending to hide that color in SpriteKit
        context.setFillColor(gray: 1, alpha: 1)
        
        /// draw the rounded rectangle with the shadow
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath
        context.addPath(path)
        context.fillPath()
    }
    
    /// Convert the image to an SKTexture
    return SKTexture(image: image)
}

// MARK: - Checkerboard

func generateCheckerboardTexture(cellSize: CGFloat, rows: Int, cols: Int) -> SKTexture {
    let size = CGSize(width: CGFloat(cols) * cellSize, height: CGFloat(rows) * cellSize)
    
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { ctx in
        let context = ctx.cgContext
        
        /// Draw checkerboard cells
        for row in 0..<rows {
            for col in 0..<cols {
                /// Determine cell color: black for even sum of indexes, white for odd
                let isBlackCell = ((row + col) % 2 == 0)
                context.setFillColor(isBlackCell ? SKColor(white: 0, alpha: 1).cgColor : SKColor(white: 1, alpha: 1).cgColor)
                
                /// Calculate cell frame
                let cellFrame = CGRect(x: CGFloat(col) * cellSize, y: CGFloat(row) * cellSize, width: cellSize, height: cellSize)
                
                /// Fill cell
                context.fill(cellFrame)
            }
        }
    }
    
    return SKTexture(image: image)
}

// MARK: - Grid

func generateGridTexture(cellSize: CGFloat, rows: Int, cols: Int, color: SKColor) -> SKTexture {
    /// Add 1 to the height and width to ensure the borders are within the sprite
    let size = CGSize(width: CGFloat(cols) * cellSize + 1, height: CGFloat(rows) * cellSize + 1)
    
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { ctx in
        //let context = ctx.cgContext
        
        /// set shadows?
        //let shadowColor = SKColor(white: 0, alpha: 0.6).cgColor
        //context.setShadow(offset: CGSize(width: 0, height: 2), blur: 1, color: shadowColor)
        
        /// fill the background?
        //context.setFillColor(SKColor(white: 1, alpha: 0.2).cgColor)
        //context.fill(CGRect(origin: .zero, size: size))
        
        let bezierPath = UIBezierPath()
        let offset: CGFloat = 0.5
        /// vertical lines
        for i in 0...cols {
            let x = CGFloat(i) * cellSize + offset
            bezierPath.move(to: CGPoint(x: x, y: 0))
            bezierPath.addLine(to: CGPoint(x: x, y: size.height))
        }
        /// horizontal lines
        for i in 0...rows {
            let y = CGFloat(i) * cellSize + offset
            bezierPath.move(to: CGPoint(x: 0, y: y))
            bezierPath.addLine(to: CGPoint(x: size.width, y: y))
        }
        
        /// stroke style
        color.setStroke()
        bezierPath.lineWidth = 1
        
        /// draw
        bezierPath.stroke()
    }
    
    return SKTexture(image: image)
}
