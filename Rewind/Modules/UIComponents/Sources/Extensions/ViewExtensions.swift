import SwiftUI

struct ViewBorder {
    var color: Color
    var width: CGFloat
    var cornerRadius: CGFloat
}

extension View {
    public func disabledWithOpacity(_ trueFlag: Bool) -> some View {
        self
            .disabled(trueFlag)
            .opacity(trueFlag ? 0.5 : 1)
    }
    
    @ViewBuilder @MainActor
    func border(_ border: ViewBorder?) -> some View {
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
}

