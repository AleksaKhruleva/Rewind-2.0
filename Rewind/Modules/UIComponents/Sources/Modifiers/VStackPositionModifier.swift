import SwiftUI

public struct VStackPositionModifier: ViewModifier {
    private let topOffsetRatio: CGFloat
    
    public init(topOffsetRatio: CGFloat) {
        self.topOffsetRatio = topOffsetRatio
    }
    
    public func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .frame(maxWidth: .infinity)
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height * topOffsetRatio
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    VStack {
        Text("test1")
        Text("test2")
    }
    .modifier(
        VStackPositionModifier(
            topOffsetRatio: AuthConstants.contentTopOffsetRatio
        )
    )
}
