import SwiftUI

public struct AppIconTaskModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .frame(width: 62, height: 24)
            .background(UIComponentsAsset.appIconLightGray.swiftUIColor)
            .foregroundColor(UIComponentsAsset.appIconText.swiftUIColor)
            .cornerRadius(8)
            .offset(y: 31)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(UIComponentsAsset.appIconDarkGray.swiftUIColor), lineWidth: 2)
                    .offset(y: 31)
            )
    }
}
