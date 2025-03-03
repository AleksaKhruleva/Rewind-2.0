import SwiftUI

public struct GradientModifier: ViewModifier {
    private let colors: [Color]
    private let locations: [CGFloat]
    private let startPoint: UnitPoint
    private let endPoint: UnitPoint
    private let applyToForeground: Bool
    
    public init(
        colors: [Color],
        locations: [CGFloat],
        startPoint: UnitPoint,
        endPoint: UnitPoint,
        applyToForeground: Bool
    ) {
        self.colors = colors
        self.locations = locations
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.applyToForeground = applyToForeground
    }
    
    public func body(content: Content) -> some View {
        if applyToForeground {
            content
                .foregroundStyle(
                    LinearGradient(
                        stops: zip(colors, locations).map {
                            Gradient.Stop(color: $0.0, location: $0.1)
                        },
                        startPoint: startPoint,
                        endPoint: endPoint
                    )
                )
        } else {
            content
                .background(
                    LinearGradient(
                        stops: zip(colors, locations).map {
                            Gradient.Stop(color: $0.0, location: $0.1)
                        },
                        startPoint: startPoint,
                        endPoint: endPoint
                    )
                )
        }
    }
}

#Preview {
    Text("Gradient Text")
        .font(.system(size: 50, weight: .semibold, design: .rounded))
        .modifier(
            GradientModifier(
                colors: [Color.blue, Color.cyan, Color.indigo],
                locations: [0.0, 0.5, 1.0],
                startPoint: .leading,
                endPoint: .trailing,
                applyToForeground: true
            )
        )
}
