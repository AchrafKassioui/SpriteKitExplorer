/**
 
 # SwiftUI Custom Button Style
 
 Created: 26 December 2023
 Updated: 20 January 2024
 
 */

import SwiftUI

// MARK: - Toggle Switch

public struct CustomToggleSwitch: View {
    @Binding var isToggled: Bool
    let iconOn: Image
    let iconOff: Image
    let labelOn: String
    let labelOff: String
    let onToggle: (Bool) -> Void
    
    let buttonWidth: Double = 60
    let buttonheight: Double = 60
    
    public init(
        isToggled: Binding<Bool>,
        iconOn: Image,
        labelOn: String,
        iconOff: Image,
        labelOff: String,
        onToggle: @escaping (Bool) -> Void
    ) {
        self._isToggled = isToggled
        self.iconOn = iconOn
        self.labelOn = labelOn
        self.iconOff = iconOff
        self.labelOff = labelOff
        self.onToggle = onToggle
    }
    
    public var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: buttonWidth, height: buttonheight)
//            .overlay(
//                Circle()
//                    .fill(isToggled ? Color.green : Color.clear)
//                    .stroke(Color.black.opacity(0.3))
//                    .offset(y: -buttonheight/2 + 10)
//                    .frame(width: 8, height: 8)
//            )
            .overlay (
                VStack (spacing: 10) {
//                    Circle()
//                        .fill(isToggled ? Color.green : Color.clear)
//                        .stroke(Color.black.opacity(0.3))
//                    //.offset(y: -buttonheight/2 + 10)
//                        .frame(width: 8, height: 8)
                    
                    (isToggled ? iconOn : iconOff)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(isToggled ? .black.opacity(0.8) : .black.opacity(0.3))
                        .frame(width: 24, height: 24)
                    
                    Text(isToggled ? labelOn : labelOff)
                        .font(.system(size: 10))
                        .multilineTextAlignment(.center)
                }
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isToggled = true
                        onToggle(isToggled)
                    }
                    .onEnded { _ in
                        isToggled = false
                        onToggle(isToggled)
                    }
            )
    }
}

// MARK: - Primitive button no background

public struct iconNoBackground: PrimitiveButtonStyle {
    @State private var isPressed = false
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 60, height: 60)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            configuration.trigger()
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

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
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(.black.opacity(0.6), lineWidth: 1)
                    )
            )
            .contentShape(Circle())
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
    @State var isToggled: Bool = false
    var body: some View {
        VStack {
            
            CustomToggleSwitch(
                isToggled: $isToggled,
                iconOn: Image(systemName: "togglepower"),
                labelOn: "ON",
                iconOff: Image(systemName: "poweroff"),
                labelOff: "OFF",
                onToggle: { isToggled in
                    print(isToggled)
                }
            )
            .background(.white.opacity(0.7))
            
            // ------------------------------------------------
            
            Button {
                print("iconNoBackground tapped")
            } label: {
                Image(systemName: "square")
            }
            .buttonStyle(iconNoBackground())
            .background(.white.opacity(0.7))
            
            // ------------------------------------------------
            
            Button {
                print("squareButtonStyle tapped")
            } label: {
                Image(systemName: "square")
            }
            .buttonStyle(squareButtonStyle())
            .background(.white.opacity(0.7))
            
            // ------------------------------------------------
            
            Button {
                print("roundButtonStyle tapped")
            } label: {
                Image(systemName: "gearshape.2")
            }
            .buttonStyle(roundButtonStyle())
            
            // ------------------------------------------------
            
            Button {
                print("roundButtonStyleWithStandardBehavior tapped")
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
                print("Long Press Started")
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.3))
    }
}

#Preview {
    firstButtonStylePreview()
}
