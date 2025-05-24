import SwiftUI

public struct RewindSearchField: View {
    @Binding var text: String
    private let placeholder: String
    private let backgroundColor: Color

    public init(
        text: Binding<String>,
        placeholder: String,
        backgroundColor: Color = Color.backgroundSecondary
    ) {
        self._text = text
        self.placeholder = placeholder
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .modifier(RoundFontModifier(size: 20))
                .frame(width: 34, height: 34)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .modifier(RoundFontModifier(size: 17))
                .padding(.trailing, text.isEmpty ? 0 : 8)
                .tint(.pinkPrimary)
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark")
                        .modifier(RoundFontModifier(size: 15))
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding()
        .frame(height: 50)
        .background(backgroundColor)
        .cornerRadius(20)
    }
}

#Preview {
    RewindSearchField(text: .constant(""), placeholder: "What?")
}
