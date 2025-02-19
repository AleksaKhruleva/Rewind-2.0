import SwiftUI
import UIComponents

public struct PasswordInputView: View {
    @State private var password: String = ""
    @FocusState private var isFocused: Bool
    
    public init() { }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            BackButton(direction: .left) {
                // TODO: do something later
            }
            .modifier(BackButtonPositionModifier())
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text("Enter your password")
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                StyledTextField(
                    text: $password,
                    placeholder: "password",
                    isSecure: true
                )
                .multilineTextAlignment(.center)
                .focused($isFocused)
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
    PasswordInputView()
}
