import SwiftUI
import UIComponents

public struct PasswordInputView: View {
    @State private var password: String = ""
    
    public init() { }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            BackButton(direction: .left) {
                // TODO: do something later
            }
            .modifier(BackButtonPositionModifier())
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text("Enter your password")
                    .foregroundStyle(Color.primaryColor)
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                StyledTextField(
                    text: $password,
                    placeholder: "password",
                    isSecure: true
                )
                .multilineTextAlignment(.center)
            }
            .modifier(VStackPositionModifier(topOffsetRatio: AuthConstants.contentTopOffsetRatio))
        }
        .hideKeyboardOnTap()
        .hideKeyboardOnDrag()
    }
}

#Preview {
    PasswordInputView()
}
