import SwiftUI

public struct HideKeyboardOnTapModifier: ViewModifier {
    public init() { }
    
    public func body(content: Content) -> some View {
        content
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        content.hideKeyboard()
                    }
            )
    }
}
