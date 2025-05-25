import SwiftUI
import AccessibilitySupport

public struct CodeInputTextField: View {
    @Binding
    var code: [String]
    var backgroundColor: UIColor
    // TODO: use error for borders
    var error: Error?
    var accessibilityElement: RewindElement?
    var onCodeFilled: () -> Void

    @State
    private var focusedField: Int = -1

    public init(
        code: Binding<[String]>,
        error: Error? = nil,
        backgroundColor: UIColor,
        accessibilityElement: RewindElement? = nil,
        onCodeFilled: @escaping () -> Void
    ) {
        self._code = code
        self.error = error
        self.backgroundColor = backgroundColor
        self.accessibilityElement = accessibilityElement
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
                .ifLet(accessibilityElement) { view, value in
                    view.applyAccessibility(for: value, withIndex: index)
                }
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

extension View {
    @ViewBuilder
    fileprivate func applyAccessibility(for element: RewindElement, withIndex index: Int) -> some View {
        switch element {
        case .auth(.input(.code)):
            self.rewindAccessibilityIdentifier(.auth(.input(.code(index))))
        case .account(.editFlow(.password)):
            self.rewindAccessibilityIdentifier(.account(.editFlow(.password(.code(index)))))
        case .account(.editFlow(.email)):
            self.rewindAccessibilityIdentifier(.account(.editFlow(.email(.code(index)))))
        default:
            self
        }
    }
}
