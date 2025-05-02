import SwiftUI
import UIComponents

public struct EmailInputView: View {
    @State var viewModel: EmailInputViewModel
    @FocusState private var isFocused: Bool
    
    @Environment(\.dismiss)
    private var dismiss
    
    public init(flow: AuthFlow, router: AuthenticationRouter) {
        viewModel = .init(flow: flow, router: router)
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color.background.ignoresSafeArea()
            
            RewindHeader {
                RewindButton(type: .leftChevron) { dismiss() }
            }
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text("What's your email?")
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                StyledTextField(
                    text: $viewModel.email,
                    placeholder: "email@email.ru",
                    keyboardType: .emailAddress
                )
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .onSubmit {
                    Task {
                        await viewModel.dispatch(.submitEmail)
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
