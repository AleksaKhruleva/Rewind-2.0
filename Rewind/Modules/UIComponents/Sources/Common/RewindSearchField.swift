import SwiftUI

public struct RewindSearchField: View {
    @Binding var text: String
    private let placeholder: String
    
    public init(text: Binding<String>, placeholder: String) {
        self._text = text
        self.placeholder = placeholder
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
        }
        .padding()
        .frame(height: 50)
        .background(UIComponentsAsset.tableBackgroundColor.swiftUIColor)
        .cornerRadius(20)
    }
}

#Preview {
    RewindSearchField(text: .constant(""), placeholder: "What?")
}
