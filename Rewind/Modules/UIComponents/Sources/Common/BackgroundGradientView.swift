import SwiftUI

public struct BackgroundGradientView: View {
    private var height: CGFloat

    public init(height: CGFloat) {
        self.height = height
    }

    public var body: some View {
        LinearGradient(
            stops: [
                Gradient.Stop(color: .clear, location: 0),
                Gradient.Stop(color: .black.opacity(0.3), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .frame(height: height)
        .allowsHitTesting(false)
    }
}
