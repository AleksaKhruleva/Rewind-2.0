import SwiftUI

public struct RoundFontModifier: ViewModifier {
    private let size: CGFloat
    private let weight: Font.Weight
    
    public init(size: CGFloat, weight: Font.Weight = .bold) {
        self.size = size
        self.weight = weight
    }
    
    public func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight, design: .rounded))
            .foregroundStyle(Color.primaryColor)
    }
}

#Preview {
    Text("Preview text")
        .modifier(RoundFontModifier(size: 15))
}
