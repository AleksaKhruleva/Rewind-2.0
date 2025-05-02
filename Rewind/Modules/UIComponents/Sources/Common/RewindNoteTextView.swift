import SwiftUI

public struct RewindNoteTextView: View {
    private let text: String
    
    public init(text: String) {
        self.text = text
    }
    
    public var body: some View {
        Text(text)
            .modifier(RoundFontModifier(
                    size: 14,
                    weight: .bold,
                    foregroundColor: UIComponentsAsset.textTertiary.swiftUIColor
                )
            )
    }
}

#Preview {
    RewindNoteTextView(text: "🙀  The end")
}
