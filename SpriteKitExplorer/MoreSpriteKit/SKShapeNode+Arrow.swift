//
//  MoreSpriteKit
//
//  https://github.com/sanderfrenken/MoreSpriteKit
//

import SpriteKit

public extension SKShapeNode {
    
    convenience init(arrowWithFillColor fillColor: SKColor, strokeColor: SKColor, lineWidth: CGFloat, length: CGFloat, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat) {
        let arrowPath = UIBezierPath(arrowFromStart: .zero, to: CGPoint(x: 0, y: length), tailWidth: tailWidth, headWidth: headWidth, headLength: headLength).cgPath
        self.init(path: arrowPath)
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
    }
}

public extension UIBezierPath {
    
    convenience init (arrowFromStart start: CGPoint, to end: CGPoint, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat) {
        let length = hypot(end.x - start.x, end.y - start.y)
        let tailLength = length - headLength
        
        let points: [CGPoint] = [
            .init(x: 0, y: tailWidth / 2),
            .init(x: tailLength, y: tailWidth / 2),
            .init(x: tailLength, y: headWidth / 2),
            .init(x: length, y: 0),
            .init(x: tailLength, y: -headWidth / 2),
            .init(x: tailLength, y: -tailWidth / 2),
            .init(x: 0, y: -tailWidth / 2)
        ]
        
        let cosine = (end.x - start.x) / length
        let sine = (end.y - start.y) / length
        let transform = CGAffineTransform(a: cosine, b: sine, c: -sine, d: cosine, tx: start.x, ty: start.y)
        let path = CGMutablePath()
        path.addLines(between: points, transform: transform)
        path.closeSubpath()
        self.init(cgPath: path)
    }
}
