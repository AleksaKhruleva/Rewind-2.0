import SwiftUI
import UIComponents

public struct EmailInputView: View {
    @State private var email: String = ""
    @FocusState private var isFocused: Bool
    private let flow: AuthFlow
    
    var router: AuthenticationRouter
    
    @Environment(\.dismiss)
    private var dismiss
    
    public init(flow: AuthFlow, router: AuthenticationRouter) {
        self.flow = flow
        self.router = router
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            RewindHeader {
                RewindButton(type: .leftChevron) { dismiss() }
            }
            
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
                .onSubmit {
                    switch flow {
                    case .registration:
                        router.navigateToCode()
                    case .login:
                        router.navigateToPassword(for: flow)
                    }
                }
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
    let router = AppRouter()
    EmailInputView(flow: .registration, router: .init(appRouter: router))
}
