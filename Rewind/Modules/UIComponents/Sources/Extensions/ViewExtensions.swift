import SwiftUI

public struct ViewBorder {
    var color: Color
    var width: CGFloat
    var cornerRadius: CGFloat

    public init(color: Color, width: CGFloat, cornerRadius: CGFloat) {
        self.color = color
        self.width = width
        self.cornerRadius = cornerRadius
    }
}

extension View {
    public func disabledWithOpacity(_ trueFlag: Bool) -> some View {
        self.disabled(trueFlag).opacity(trueFlag ? 0.5 : 1)
    }

    @ViewBuilder @MainActor
    public func border(_ border: ViewBorder?) -> some View {
        if let border {
            overlay {
                RoundedRectangle(cornerRadius: border.cornerRadius)
                    .strokeBorder(
                        border.color,
                        lineWidth: border.width
                    )
                    .allowsHitTesting(false)
            }
        } else {
            self
        }
    }

    public func frame(_ size: CGFloat) -> some View {
        self.frame(width: size, height: size)
    }

    @ViewBuilder
    public func loadingOverlayIfNeeded(_ condition: Bool) -> some View {
        if condition {
            self.overlay {
                ZStack {
                    Color.backgroundSecondary.opacity(0.5)

                    ProgressView()
                }
            }
        } else { self }
    }
}
