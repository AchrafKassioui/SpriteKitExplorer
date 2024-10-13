/**
 
 # SwiftUI Playground
 
 A file to try out SwiftUI
 
 Achraf Kassioui
 Created: 13 June 2024
 Updated: 13 June 2024
 
 */

import SwiftUI
import SpriteKit

struct SwiftUIPlaygroundView: View {
    @State var wheelRotation: Double = 0
    @State private var recordingRegion = CGRect.zero
    
    var body: some View {
        GeometryReader() { geo in
            ZStack {
                RotationWheelView1(rotation: $wheelRotation)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.gray)
        }
    }
}

#Preview {
    SwiftUIPlaygroundView()
}

struct RotationWheelView: View {
    @Binding var rotation: Double
    
    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: 160, height: 160)
            .overlay (
                ForEach(1...12, id: \.self) { i in
                    Rectangle()
                        .fill(.black.opacity(0.6))
                        .frame(width: 3, height: 12)
                        .offset(y: -74)
                        .rotationEffect(.degrees(Double(i * 30)))
                }
            )
            .overlay (
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 4, height: 40)
            )
            .valueRotationInertia(
                totalAngle: $rotation,
                friction: .constant(0.05),
                onAngleChanged: { angle in
                    print(angle)
                }
            )
            .shadow(radius: 3, y: 4)
    }
}

struct RotationWheelView1: View {
    @Binding var rotation: Double
    
    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: 160, height: 160)
            .overlay (
                ForEach(1...12, id: \.self) { i in
                    Rectangle()
                        .fill(.black.opacity(0.6))
                        .frame(width: 3, height: 12)
                        .offset(y: -74)
                        .rotationEffect(.degrees(Double(i * 30)))
                }
            )
            .overlay (
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 4, height: 40)
            )
            .simpleRotationInertia(
                friction: .constant(0.03),
                angleSnap: .constant(90),
                angleSnapShowFactor: .constant(10)
            )
            .onChange(of: rotation) {
                print(rotation)
            }
            .shadow(radius: 3, y: 4)
    }
}
