import SwiftUI
import AccessibilitySupport

public struct CodeInputTextField: View {
    @Binding
    var code: [String]
    var backgroundColor: UIColor
    // TODO: use error for borders
    var error: Error?
    var onCodeFilled: () -> Void

    @State
    private var focusedField: Int = -1

    public init(
        code: Binding<[String]>,
        error: Error? = nil,
        backgroundColor: UIColor,
        onCodeFilled: @escaping () -> Void
    ) {
        self._code = code
        self.error = error
        self.backgroundColor = backgroundColor
        self.onCodeFilled = onCodeFilled
    }

    var joinedCode: String {
        code.joined()
    }

    public var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { index in
                CodeDigitTextFieldAdapter(
                    code: $code,
                    focusedField: $focusedField,
                    backgroundColor: backgroundColor,
                    tag: index
                )
                    .frame(width: 60, height: 75)
                    .rewindAccessibilityIdentifier(.auth(.input(.code(index))))
            }
        }
        .onChange(of: code) { _, newValue in focusedField = newValue.count }
        .onChange(of: joinedCode.count == 4) { _, newValue in
            if newValue {
                onCodeFilled()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + AuthConstants.keyboardFocusDelay) {
                focusedField = 0
            }
        }
    }
}
