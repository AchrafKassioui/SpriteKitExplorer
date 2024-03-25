/**
 
 # Generate a Grid
 
 This file generates a grid image in PNG format.
 The image is generated with Core Graphics, then written to disc.
 
 You run it by pressing the "Generate Grid" button in the SwiftUI live preview.
 
 Created: 21 March 2024
 
 */

import SwiftUI

/// SwiftUI view
struct GenerateGridImageUI: View {
    var body: some View {
        Button(action: {
            generatePNG()
        }, label: {
            Text("Generate Grid")
                .font(.title2)
        })
        .buttonStyle(.borderedProminent)
        Text("The file path of the generated image will be printed in the console.")
            .padding(20)
            .multilineTextAlignment(.center)
    }
}

/// this will run the live preview in Xcode
#Preview {
    GenerateGridImageUI()
}

/**

 Configure your grid here:
 - Parameter cellSize: the width, in points, of a square in the grid
 - Parameter rows: the number of horizontal squares in the grid
 - Parameter columns: the number of vertical squares in the grid
 
 The actual size of the image in pixels depends on the device you are running on.
 If the device runs at 3x scalling like most recent iPhones, then a 1 point = 3 pixels
 If the device is a retina Mac, then 1 point = 2 pixels
 
 */
func generatePNG() {
    if let pngData = generateGrid(cellSize: 50, rows: 10, cols: 10) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = paths[0].appendingPathComponent("grid.png")
        
        do {
            try pngData.write(to: filePath)
            print("Saved grid image at: \(filePath)")
        } catch {
            print("Failed to save image: \(error)")
        }
    }
}

/// The Core Graphics function
func generateGrid(cellSize: CGFloat, rows: Int, cols: Int) -> Data? {
    let size = CGSize(width: CGFloat(cols) * cellSize + 1, height: CGFloat(rows) * cellSize + 1)
    
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { ctx in
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
        
        /// the color of the strokes
        UIColor(white: 0, alpha: 1).setStroke()
        
        /// the thickness of the strokes
        bezierPath.lineWidth = 1
        
        bezierPath.stroke()
    }
    
    return image.pngData()
}
