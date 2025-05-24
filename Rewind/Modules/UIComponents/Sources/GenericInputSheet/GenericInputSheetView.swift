import SwiftUI

public struct GenericInputSheetView: View {
    private var item: GenericInputSheetItem
    private var title: String
    private var placeholder: String?
    private var action: (String) -> Void
    @Binding var error: String?
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    @Environment(\.dismiss)
    private var dismiss

    private var keyboardType: UIKeyboardType {
        switch item {
        case .name, .password, .tag, .code: .default
        case .email: .emailAddress
        }
    }

    public init(
        item: GenericInputSheetItem,
        title: String,
        placeholder: String? = nil,
        error: Binding<String?>,
        action: @escaping (String) -> Void
    ) {
        self.item = item
        self.title = title
        self.placeholder = placeholder
        self._error = error
        self.action = action
    }

    public var body: some View {
        ZStack {
            Color.backgroundSecondary.ignoresSafeArea()

            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text(title)
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))

                switch item {
                case .name, .password, .email, .tag:
                    StyledTextField(
                        text: $text,
                        placeholder: placeholder ?? "",
                        keyboardType: keyboardType,
                        isSecure: item == .password
                    )
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                    .onSubmit {
                        action(text)
                    }
                case .code:
                    CodeInputTextField(
                        code: Binding<[String]>(
                            get: {
                                let chars = text.map { String($0) }
                                let paddingCount = max(0, 4 - chars.count)
                                return chars + Array(repeating: "", count: paddingCount)
                            },
                            set: { newArray in
                                text = newArray.joined()
                            }
                        ),
                        error: nil,
                        backgroundColor: UIComponentsAsset.background.color
                    ) {
                        action(text)
                    }
                    .allowsHitTesting(false)
                }
                if let error {
                    RewindNoteTextView(text: error)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}
