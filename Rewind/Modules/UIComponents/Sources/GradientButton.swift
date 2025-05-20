import SwiftUI

public struct GradientButton: View {
    public enum Width {
        case generic
        case given(CGFloat)
    }
    
    private let title: String
    private let width: Width
    private let action: () -> Void
    
    public init(title: String, width: Width, action: @escaping () -> Void) {
        self.width = width
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .modifier(RoundFontModifier(size: 18, foregroundColor: .white))
                .setFrame(width: width, height: 45)
                .modifier(
                    GradientModifier(
                        colors: [
                            Color(hex: "FF3299"),
                            Color(hex: "FF65B5"),
                            Color(hex: "FF8FC7")
                        ],
                        locations: [0, 0.5, 1],
                        startPoint: .leading,
                        endPoint: .trailing,
                        applyToForeground: false
                    )
                )
                .clipShape(Capsule())
        }
    }
}

extension View {
    @ViewBuilder
    fileprivate func setFrame(width: GradientButton.Width, height: CGFloat) -> some View {
        switch width {
        case .generic:
            self
                .padding(.horizontal, 24)
                .frame(height: height)
        case let .given(value):
            self.frame(width: value, height: height)
        }
    }
}

#Preview {
    GradientButton(title: "Зарегистрироваться", width: .given(100)) {
        print("Tapped")
    }
    
    GradientButton(title: "Register", width: .given(100)) {
        print("Tapped")
    }
}
