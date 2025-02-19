import SwiftUI
import UIComponents

public struct CodeInputView: View {
    @State private var code: String = ""
    @FocusState private var isFocused: Bool
    
    public init() { }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            BackButton(direction: .left) {
                // TODO: do something later
            }
            .modifier(BackButtonPositionModifier())
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text("Enter code from email")
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                StyledTextField(
                    text: $code,
                    placeholder: "",
                    keyboardType: .numberPad,
                    frameWidth: .zero,
                    frameHeight: .zero
                )
                .focused($isFocused)
                .onChange(of: code) { oldValue, newValue in
                    // TODO: move this to ViewModel later
                    if newValue.count == CodeConstants.numberOfDigits {
                        let isValidCode = Bool.random() // TODO: replace with real check later
                        if !isValidCode {
                            code = ""
                        } else {
                            isFocused = false
                        }
                    }
                }
                
                CodeView(code: $code, isFocused: _isFocused)
            }
            .modifier(VStackPositionModifier(topOffsetRatio: AuthConstants.contentTopOffsetRatio))
        }
        .onAppear {
            isFocused = true
        }
        .hideKeyboardOnTap()
        .hideKeyboardOnDrag()
    }
}

#Preview {
    CodeInputView()
}
