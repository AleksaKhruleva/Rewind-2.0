import SwiftUI
import UIComponents

public struct EmailInputView: View {
    @State private var email: String = ""
    
    public init() { }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            BackButton(direction: .left) {
                // TODO: do something later
            }
            .modifier(BackButtonPositionModifier())
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text("What's your email?")
                    .foregroundStyle(Color.primaryColor)
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                StyledTextField(
                    text: $email,
                    placeholder: "email@email.ru",
                    keyboardType: .emailAddress
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
    EmailInputView()
}
