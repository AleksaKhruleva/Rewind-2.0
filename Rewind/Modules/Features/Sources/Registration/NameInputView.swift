import SwiftUI
import UIComponents

public struct NameInputView: View {
    @State private var email: String = ""
    
    public init() { }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            BackButton(direction: .left) {
                // TODO: do something later
            }
            .modifier(BackButtonPositionModifier())
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text("What's your name?")
                    .foregroundStyle(Color.primaryColor)
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                StyledTextField(
                    text: $email,
                    placeholder: "name",
                    submitLabel: .continue
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
    NameInputView()
}
