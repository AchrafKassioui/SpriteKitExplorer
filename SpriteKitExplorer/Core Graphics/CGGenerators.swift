/**
 
 # Core Graphics Generators
 
 Methods that generate textures for use in SpriteKit.
 
 Created: 18 March 2024
 Updated: 19 April 2024
 
 */

import SpriteKit

// MARK: - Stripes

func generateStripedTexture(size: CGSize, colorA: SKColor, colorB: SKColor, stripeHeight: CGFloat) -> SKTexture {
    let renderer = UIGraphicsImageRenderer(size: size)
    
    let image = renderer.image { context in
        /// calculate the number of stripes needed
        let numStripes = Int(ceil(size.height / stripeHeight))
        
        /// draw alternating stripes
        for i in 0..<numStripes {
            let stripeY = CGFloat(i) * stripeHeight
            let stripeRect = CGRect(x: 0, y: stripeY, width: size.width, height: stripeHeight)
            let color = (i % 2 == 0) ? colorA : colorB
            color.setFill()
            context.fill(stripeRect)
        }
    }
    
    return SKTexture(image: image)
}

// MARK: - Dot Pattern

enum DotPatternType {
    case regular
    case staggered
}

func generateDotPatternTexture(
    size: CGSize,
    color: SKColor,
    pattern: DotPatternType,
    dotSize: CGFloat? = 2,
    spacing: CGFloat? = nil,
    cornerRadius: CGFloat? = nil,
    rotation: CGFloat? = nil
) -> SKTexture {
    let dotRadius: CGFloat = (dotSize ?? 1) * 0.5
    let spacing: CGFloat = spacing ?? (dotRadius * 0.5)
    let renderer = UIGraphicsImageRenderer(size: size)
    
    let image = renderer.image { context in
        /// The background color of the texture.
        /// By default, it's transparent.
        SKColor.clear.setFill()
        context.fill(CGRect(origin: .zero, size: size))
        
        /// If asked, rotate the texture around its visual center
        /// The origin of the coordinate system with UIGraphicsImageRenderer is in the top left
        /// To pivot around the center, we move the origin (the rotation pivot) to the center, rotate, then put it back.
        if let rotation = rotation {
            context.cgContext.translateBy(x: size.width / 2, y: size.height / 2)
            context.cgContext.rotate(by: rotation)
            context.cgContext.translateBy(x: -size.width / 2, y: -size.height / 2)
        }
        
        /// If asked, clip the context with a rounded rect
        if let cornerRadius = cornerRadius {
            let clippingPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: cornerRadius)
            clippingPath.addClip()
        }
        
        /// Set a color for the drawing
        color.setFill()
        
        switch pattern {
        case .regular:
            for y in stride(from: 0, to: size.height, by: dotRadius * 2 + spacing) {
                for x in stride(from: 0, to: size.width, by: dotRadius * 2 + spacing) {
                    let dotPath = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: dotRadius * 2, height: dotRadius * 2))
                    dotPath.fill()
                }
            }
            
        case .staggered:
            var rowIndex = 0
            for y in stride(from: dotRadius, to: size.height, by: dotRadius * 2 + spacing) {
                /// Alternate xOffset based on whether the row is odd or even
                let xOffset = rowIndex % 2 == 0 ? 0 : dotRadius + spacing / 2
                for x in stride(from: xOffset, to: size.width, by: dotRadius * 2 + spacing) {
                    let dotPath = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: dotRadius * 2, height: dotRadius * 2))
                    dotPath.fill()
                }
                rowIndex += 1
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

// MARK: - Grid Generator
/**
 
 This function returns a empty texture if the expected size exceeds Metal texture size limit.
 The current limit is 8192x8192, which is the maximum size allowed in Xcode live preview.
 
 */

func generateGridTexture(cellSize: CGFloat, rows: Int, cols: Int, linesColor: SKColor) -> SKTexture {
    let backgroundColor: SKColor = .clear
    
    /**
     Shadow settings examples:
     - Bump tiles:  shadow color = white, offset = CGSize(width: 3, height: 3), blur = 3
     */
    let lineShadowColor: SKColor = .clear
    let lineShadowOffset: CGSize = CGSize(width: 3, height: 3)
    let shadowBlur: CGFloat = 3
    
    /// calculate the initial size of the texture in points
    let widthInPoints = CGFloat(cols) * cellSize + 1
    let heightInPoints = CGFloat(rows) * cellSize + 1
    
    /// get the screen scale to convert points to pixels
    let scale = UIScreen.main.scale
    let widthInPixels = widthInPoints * scale
    let heightInPixels = heightInPoints * scale
    
    /// check if the size exceeds Metal texture size limit
    if widthInPixels > 8192 || heightInPixels > 8192 {
        print("generateGridTexture: size exceeds Metal texture size limit.")
        /// if so, create and return a clear (empty) texture
        let emptyRenderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let emptyImage = emptyRenderer.image { _ in }
        return SKTexture(image: emptyImage)
    }
    
    /// Add 1 to the height and width to ensure the borders are within the sprite
    let size = CGSize(width: CGFloat(cols) * cellSize + 1, height: CGFloat(rows) * cellSize + 1)
    
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { ctx in
        let context = ctx.cgContext
        
        /// set shadows?
        if lineShadowColor != .clear {
            let shadowColor = lineShadowColor.cgColor
            context.setShadow(offset: lineShadowOffset, blur: shadowBlur, color: shadowColor)
        }
        
        /// fill the background?
        if backgroundColor != .clear {
            context.setFillColor(backgroundColor.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }
        
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
        linesColor.setStroke()
        bezierPath.lineWidth = 1
        
        /// draw
        bezierPath.stroke()
    }
    
    return SKTexture(image: image)
}

// MARK: - Grid Generator, for Swift 6
/**
 
 This function returns a empty texture if the expected size exceeds Metal texture size limit.
 The current limit is 8192x8192, which is the maximum size allowed in Xcode live preview.
 
 */

func generateGridTexture(cellSize: CGFloat, rows: Int, cols: Int, linesColor: SKColor) async -> UIImage {
    return await withCheckedContinuation { continuation in
        /// Perform work in a background task
        Task.detached {
            let backgroundColor: SKColor = .clear
            let lineShadowColor: SKColor = .clear
            let lineShadowOffset: CGSize = CGSize(width: 3, height: 3)
            let shadowBlur: CGFloat = 3
            
            let widthInPoints = CGFloat(cols) * cellSize + 1
            let heightInPoints = CGFloat(rows) * cellSize + 1
            let widthInPixels = widthInPoints
            let heightInPixels = heightInPoints
            
            if widthInPixels > 8192 || heightInPixels > 8192 {
                print("generateGridTexture: size exceeds Metal texture size limit.")
                let emptyRenderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
                let emptyImage = emptyRenderer.image { _ in }
                //continuation.resume(returning: SKTexture(image: emptyImage))
                continuation.resume(returning: emptyImage)
                return
            }
            
            let size = CGSize(width: CGFloat(cols) * cellSize + 1, height: CGFloat(rows) * cellSize + 1)
            let renderer = UIGraphicsImageRenderer(size: size)
            
            // Create the image in the background task
            let image = renderer.image { ctx in
                let context = ctx.cgContext
                if lineShadowColor != .clear {
                    let shadowColor = lineShadowColor.cgColor
                    context.setShadow(offset: lineShadowOffset, blur: shadowBlur, color: shadowColor)
                }
                
                if backgroundColor != .clear {
                    context.setFillColor(backgroundColor.cgColor)
                    context.fill(CGRect(origin: .zero, size: size))
                }
                
                let bezierPath = UIBezierPath()
                let offset: CGFloat = 0.5
                for i in 0...cols {
                    let x = CGFloat(i) * cellSize + offset
                    bezierPath.move(to: CGPoint(x: x, y: 0))
                    bezierPath.addLine(to: CGPoint(x: x, y: size.height))
                }
                
                for i in 0...rows {
                    let y = CGFloat(i) * cellSize + offset
                    bezierPath.move(to: CGPoint(x: 0, y: y))
                    bezierPath.addLine(to: CGPoint(x: size.width, y: y))
                }
                
                linesColor.setStroke()
                bezierPath.lineWidth = 1
                bezierPath.stroke()
            }
            
            // Return the generated image
            continuation.resume(returning: image)
        }
    }
}
