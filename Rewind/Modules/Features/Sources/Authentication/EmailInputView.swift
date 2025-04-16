import SwiftUI
import UIComponents

public struct EmailInputView: View {
    @State private var email: String = ""
    @FocusState private var isFocused: Bool
    private let flow: AuthFlow
    
    public init(flow: AuthFlow) {
        self.flow = flow
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            BackButton(direction: .left) {
                // TODO: do something later
            }
            .modifier(BackButtonPositionModifier())
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text("What's your email?")
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                StyledTextField(
                    text: $email,
                    placeholder: "email@email.ru",
                    keyboardType: .emailAddress
                )
                .multilineTextAlignment(.center)
                .focused($isFocused)
            }
            .modifier(VStackTopOffsetModifier(topOffsetRatio: AuthConstants.contentTopOffsetRatio))
        }
        .onAppear {
            isFocused = true
        }
        .hideKeyboardOnTap()
        .hideKeyboardOnDrag()
    }
}

#Preview {
    EmailInputView(flow: .registration)
}
