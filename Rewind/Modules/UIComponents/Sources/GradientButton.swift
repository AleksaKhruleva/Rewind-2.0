import SwiftUI

public struct GradientButton: View {
    private let title: String
    private let width: CGFloat
    private let action: () -> Void
    
    public init(title: String, width: CGFloat, action: @escaping () -> Void) {
        self.width = width
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .modifier(RoundFontModifier(size: 18, foregroundColor: .white))
                .frame(width: width, height: 45)
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

#Preview {
    GradientButton(title: "Button", width: 100) {
        print("Tapped")
    }
}
