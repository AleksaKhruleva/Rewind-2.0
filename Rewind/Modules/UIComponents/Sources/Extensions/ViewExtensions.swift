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
        self.overlay {
            if condition {
                ZStack {
                    Color.backgroundSecondary.opacity(0.5)

                    ProgressView()
                }
            }
        }
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, apply: (Self) -> Content) -> some View {
        if condition {
            apply(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, apply: (Self, T) -> Content) -> some View {
        if let unwrapped = value {
            apply(self, unwrapped)
        } else {
            self
        }
    }
}
