import SwiftUI

public struct GalleryItemModifier: ViewModifier {
    public init() { }
    
    public func body(content: Content) -> some View {
        content
            .frame(
                width: UIScreen.main.bounds.width / 3,
                height: UIScreen.main.bounds.width / 3
            )
            .cornerRadius(14)
    }
}
