import SwiftUI

public struct BackButtonPositionModifier: ViewModifier {
    public init() { }
    
    public func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .position(
                    x: geometry.size.width * (AuthConstants.backButtonXRatio),
                    y: geometry.size.height * (AuthConstants.backButtonYRatio)
                )
        }
    }
}
