/**
 
 # SwiftUI Custom Button Style
 
 Created: 26 December 2023
 Updated: 20 January 2024
 
 */

import SwiftUI

// MARK: - Primitive Buttons

public struct squareButtonStyle: PrimitiveButtonStyle {
    @State private var isPressed = false
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.black)
            .frame(width: 60, height: 60)
            //.background(.thinMaterial.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 0))
            .overlay {
                RoundedRectangle(cornerRadius: 0)
                    //.stroke(.black.opacity(0.6), lineWidth: 1)
                    .fill(.black.opacity(isPressed ? 0.2 : 0))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            withAnimation(.bouncy(duration: 0.1)) {
                                isPressed = true
                                configuration.trigger()
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    }
                    .onEnded {_ in
                        isPressed = false
                    }
            )
    }
}

public struct roundButtonStyle: PrimitiveButtonStyle {
    @State private var isPressed = false
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.black)
            .frame(width: 60, height: 60)
            .background(.thinMaterial.opacity(0.6))
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(.black.opacity(0.6), lineWidth: 1)
                    //.fill(.black.opacity(isPressed ? 0.3 : 0))
                    //.scaleEffect(isPressed ? 0.9 : 1)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isPressed = true
                        configuration.trigger()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.linear(duration: 3/60)) {
                            isPressed = false
                        }
                    }
            )
    }
}

// MARK: - Standard Buttons

public struct roundButtonStyleWithStandardBehavior: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.black)
            .frame(width: 60, height: 60)
            .background(.regularMaterial)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(.black, lineWidth: 1)
                    .fill(.black.opacity(configuration.isPressed ? 0.3 : 0))
            }
    }
}

public struct firstButtonStyle: ButtonStyle {
    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.black.opacity(0.9))
            .frame(width: 60, height: 60)
            .background(.thinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 1)
                    .stroke(Color.black.opacity(0.9), lineWidth: 1)
                    .fill(.black.opacity(configuration.isPressed ? 0.2 : 0))
            }
            .animation(.bouncy(duration: 0), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct firstButtonStylePreview: View {
    var body: some View {
        
        // ------------------------------------------------
        
        Button {
            print("Primitive Button Style tapped")
        } label: {
            Image(systemName: "gearshape.2")
        }
        .buttonStyle(roundButtonStyle())
        
        // ------------------------------------------------
        
        Button {
            print("Button Style tapped")
        } label: {
            Image(systemName: "play.fill")
        }
        .buttonStyle(roundButtonStyleWithStandardBehavior())
        
        // ------------------------------------------------
        
        Button {
            
        } label: {
            Text("Tap")
        }
        /// Apply the custom style like this
        .buttonStyle(firstButtonStyle())
        
        /// Various tap and press listeners
        .simultaneousGesture(LongPressGesture().onChanged { _ in
            /// beginning of a long press
        })
        .simultaneousGesture(LongPressGesture().onEnded { _ in
            print("Taaaaaaap")
            /// haptic feedback
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        })
        .simultaneousGesture(TapGesture().onEnded {
            print("Tap")
        })
        .simultaneousGesture(TapGesture(count: 2).onEnded {
            print("Tap tap")
        })
        .simultaneousGesture(TapGesture(count: 3).onEnded {
            print("Tap tap tap")
        })
        .simultaneousGesture(TapGesture(count: 4).onEnded {
            print("Tap tap tap tap")
        })
        
        // ------------------------------------------------
    }
}

#Preview {
    firstButtonStylePreview()
}
