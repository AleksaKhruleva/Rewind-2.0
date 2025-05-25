import SwiftUI

public struct MeasureWidthModifier: ViewModifier {
    @Binding private var width: CGFloat

    public init(width: Binding<CGFloat>) {
        self._width = width
    }

    public func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            width = geometry.size.width
                        }
                }
            )
    }
}
