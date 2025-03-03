import SwiftUI

public struct RoundFontModifier: ViewModifier {
    private let size: CGFloat
    private let weight: Font.Weight
    private let foregroundColor: Color
    
    public init(
        size: CGFloat,
        weight: Font.Weight = .heavy,
        foregroundColor: Color = UIComponentsAsset.primaryColor.swiftUIColor
    ) {
        self.size = size
        self.weight = weight
        self.foregroundColor = foregroundColor
    }
    
    public func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight, design: .rounded))
            .foregroundStyle(foregroundColor)
    }
}

#Preview {
    Text("Preview text")
        .modifier(RoundFontModifier(size: 15))
}
