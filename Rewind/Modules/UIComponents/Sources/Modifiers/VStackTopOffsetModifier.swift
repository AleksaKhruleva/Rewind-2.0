import SwiftUI

public struct VStackTopOffsetModifier: ViewModifier {
    private let topOffsetRatio: CGFloat

    public init(topOffsetRatio: CGFloat) {
        self.topOffsetRatio = topOffsetRatio
    }

    public func body(content: Content) -> some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer().frame(height: geometry.size.height * topOffsetRatio)
                content
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    VStack {
        Text("test1")
        Text("test2")
    }
    .modifier(
        VStackTopOffsetModifier(
            topOffsetRatio: AuthConstants.contentTopOffsetRatio
        )
    )
}
