import SwiftUI

public struct ColorPickerTableCell: View {
    var text: String
    @Binding
    var color: Color
    
    @State
    private var showColorPicker = false
    
    public init(text: String, color: Binding<Color>) {
        self.text = text
        self._color = color
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            Text(text)
                .modifier(
                    RoundFontModifier(
                        size: AccountConstants.defaultFontSize,
                        weight: .bold,
                        foregroundColor: UIComponentsAsset.textPrimary.swiftUIColor
                    )
                )
                .padding(.leading, 5)
            
            Spacer()
            
            ColorPicker("", selection: $color, supportsOpacity: false).frame(width: 30)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 17))
                .fontWeight(.bold)
                .frame(width: 30, height: 30)
        }
        .foregroundColor(UIComponentsAsset.textPrimary.swiftUIColor)
        .contentShape(Rectangle())
        .onTapGesture { showColorPicker = true }
        .frame(height: 42)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
