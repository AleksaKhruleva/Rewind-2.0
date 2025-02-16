import SwiftUI

public struct HideKeyboardOnDragModifier: ViewModifier {
    public init() { }
    
    public func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture().onChanged { gesture in
                    if gesture.translation.height > 10 {
                        content.hideKeyboard()
                    }
                }
            )
    }
}
