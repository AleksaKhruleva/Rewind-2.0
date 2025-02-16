import SwiftUI

public struct StyledTextField: View {
    @Binding var text: String
    private let placeholder: String
    private let keyboardType: UIKeyboardType
    private let submitLabel: SubmitLabel
    private let isSecure: Bool
    
    public init(
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default,
        submitLabel: SubmitLabel = .done,
        isSecure: Bool = false
    ) {
        self._text = text
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.submitLabel = submitLabel
        self.isSecure = isSecure
    }
    
    public var body: some View {
        ZStack(alignment: .trailing) {
            if isSecure {
                SecureField(
                    "",
                    text: $text,
                    prompt: Text(placeholder).foregroundStyle(Color(UIColor.systemGray5))
                )
            } else {
                TextField(
                    "",
                    text: $text,
                    prompt: Text(placeholder).foregroundStyle(Color(UIColor.systemGray5))
                )
            }
        }
        .font(.system(size: 22, weight: .semibold, design: .monospaced))
        .foregroundStyle(Color.primaryColor)
        .keyboardType(keyboardType)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
        .submitLabel(submitLabel)
    }
}

#Preview {
    VStack(spacing: 20) {
        StyledTextField(
            text: .constant(""),
            placeholder: "email@email.ru",
            keyboardType: .emailAddress
        )
        
        StyledTextField(
            text: .constant(""),
            placeholder: "password",
            isSecure: true
        )
    }
}
