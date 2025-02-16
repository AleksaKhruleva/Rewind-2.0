import SwiftUI

public struct StyledTextField: View {
    @Binding var text: String
    private let placeholder: String
    private let keyboardType: UIKeyboardType
    private let submitLabel: SubmitLabel
    
    public init(
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default,
        submitLabel: SubmitLabel = .done
    ) {
        self._text = text
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.submitLabel = submitLabel
    }
    
    public var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text(placeholder).foregroundStyle(Color(UIColor.systemGray5))
        )
        .font(.system(size: 22, weight: .semibold, design: .monospaced))
        .foregroundStyle(Color.primaryColor)
        .keyboardType(keyboardType)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
        .submitLabel(submitLabel)
    }
}

#Preview {
    StyledTextField(
        text: .constant(""),
        placeholder: "email@email.ru",
        keyboardType: .emailAddress
    )
}
