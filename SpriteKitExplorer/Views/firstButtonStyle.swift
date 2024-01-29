/**
 
 # SwiftUI Custom Button Style
 
 Created: 26 December 2023
 Updated: 20 January 2024
 
 */

import SwiftUI

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
            //.opacity(configuration.isPressed ? 0.4 : 1.0)
            .animation(.bouncy(duration: 0), value: configuration.isPressed)
    }
}

/// Usage example
struct firstButtonStylePreview: View {
    var body: some View {
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
    }
}

#Preview {
    firstButtonStylePreview()
}
