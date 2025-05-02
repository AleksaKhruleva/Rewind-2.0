import SwiftUI

public struct AppIconTaskModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .frame(width: 66, height: 24)
            .background(Color.backgroundSecondary)
            .foregroundColor(.textPrimary)
            .cornerRadius(8)
            .offset(y: 31)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.iconsBorder), lineWidth: 1)
                    .offset(y: 31)
            )
    }
}

public struct TagViewModifier: ViewModifier {
    private var tags: [String]
    private var tag: String
    private var geometry: GeometryProxy
    
    public func body(content: Content) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        content
            .alignmentGuide(.leading, computeValue: { d in
                if (abs(width - d.width) > geometry.size.width)
                {
                    width = 0
                    height -= d.height
                }
                let result = width
                if tag == self.tags.last! {
                    width = 0 //last item
                } else {
                    width -= d.width
                }
                return result
            })
            .alignmentGuide(.top, computeValue: {d in
                let result = height
                if tag == self.tags.last! {
                    height = 0 // last item
                }
                return result
            })
    }
}
