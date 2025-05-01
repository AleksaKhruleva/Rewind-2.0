import SwiftUI
import UIComponents

public struct NameInputView: View {
    @State var viewModel: NameInputViewModel
    @State private var name: String = ""
    @FocusState private var isFocused: Bool
    
    @Environment(\.dismiss)
    private var dismiss
    
    public init(router: AuthenticationRouter, password: String, registrationID: String) {
        viewModel = .init(router: router, password: password, registrationID: registrationID)
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            RewindHeader {
                RewindButton(type: .leftChevron) { dismiss() }
            }
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text("What's your name?")
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                StyledTextField(
                    text: $name,
                    placeholder: "name"
                )
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
            isFocused = true
        }
        .hideKeyboardOnTap()
        .hideKeyboardOnDrag()
    }
}

#Preview {
    let router = AppRouter()
    NameInputView(router: .init(appRouter: router), password: "123", registrationID: "123")
}
