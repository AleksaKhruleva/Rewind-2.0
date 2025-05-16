import SwiftUI
import UIComponents

public struct NameInputView: View {
    @State private var viewModel: NameInputViewModel
    @State private var name: String = ""
    @FocusState private var isFocused: Bool
    
    public init(router: AuthenticationRouter, email: String, password: String, registrationID: String) {
        viewModel = .init(router: router, email: email, password: password, registrationID: registrationID)
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color.background.ignoresSafeArea()
            
            RewindHeader(leftView: {
                RewindButton(type: .leftChevron) {
                    hideKeyboard()
                    DispatchQueue.main.asyncAfter(deadline: .now() + AuthConstants.keyboardHideDelay) {
                        viewModel.router.dismiss()
                    }
                }
            })
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text(UIComponentsStrings.Name.title)
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                StyledTextField(
                    text: $name,
                    placeholder: UIComponentsStrings.Name.placeholder
                )
                .rewindAccessibilityIdentifier(.auth(.input(.name)))
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .onSubmit {
                    Task {
                        await viewModel.dispatch(.submitName(name))
                    }
                }
                
                if viewModel.state == .loading {
                    ProgressView()
                } else if case let .error(error) = viewModel.state {
                    RewindNoteTextView(text: error.errorDescription)
                        .multilineTextAlignment(.center)
                }
            }
            .modifier(VStackTopOffsetModifier(topOffsetRatio: AuthConstants.contentTopOffsetRatio))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + AuthConstants.keyboardFocusDelay) {
                isFocused = true
            }
        }
        .hideKeyboardOnTap()
        .hideKeyboardOnDrag()
    }
}

#Preview {
    let router = AppRouter()
    NameInputView(router: .init(appRouter: router), email: "", password: "123", registrationID: "123")
}
