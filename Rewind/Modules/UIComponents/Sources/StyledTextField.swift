import SwiftUI

public struct StyledTextField: View {
    @Binding private var text: String
    private let placeholder: String
    private let keyboardType: UIKeyboardType
    private let submitLabel: SubmitLabel
    private let isSecure: Bool
    private let frameWidth: CGFloat
    private let frameHeight: CGFloat
    
    public init(
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default,
        submitLabel: SubmitLabel = .done,
        isSecure: Bool = false,
        frameWidth: CGFloat = .infinity,
        frameHeight: CGFloat = .infinity
    ) {
        self._text = text
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.submitLabel = submitLabel
        self.isSecure = isSecure
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
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
        .tint(Color.pinkColor)
        .keyboardType(keyboardType)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
        .submitLabel(submitLabel)
        .frame(width: frameWidth, height: frameHeight)
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
