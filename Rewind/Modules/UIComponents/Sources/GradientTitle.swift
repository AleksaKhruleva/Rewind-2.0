import SwiftUI

public struct GradientTitle: View {
    private let text: String
    private let fontSize: CGFloat
    
    public init(text: String, fontSize: CGFloat) {
        self.text = text
        self.fontSize = fontSize
    }
    
    public var body: some View {
        Text(text)
            .font(UIComponentsFontFamily.AdvertisingScript.bold.swiftUIFont(size: fontSize))
            .modifier(
                GradientModifier(
                    colors: [
                        Color(hex: "FFAFD7"),
                        Color(hex: "ED4197"),
                        Color(hex: "FF59CD"),
                    ],
                    locations: [0.0, 0.43, 1.0],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                    applyToForeground: true
                )
            )
    }
}

#Preview {
    GradientTitle(text: "Rewind", fontSize: 80)
}
