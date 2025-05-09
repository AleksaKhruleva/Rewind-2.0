import SwiftUI
import UIComponents

public struct CodeInputView: View {
    @State var viewModel: CodeInputViewModel
    @State private var code: [String] = Array(repeating: "", count: 4)
    
    @Environment(\.dismiss)
    private var dismiss
    
    public init(router: AuthenticationRouter, email: String, registrationID: String) {
        viewModel = .init(router: router, email: email, registrationID: registrationID)
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color.background.ignoresSafeArea()
            
            RewindHeader(leftView: {
                RewindButton(type: .leftChevron) { dismiss() }
            })
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text(UIComponentsStrings.Code.title)
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                CodeInputTextField(code: $code, error: nil, backgroundColor: UIComponentsAsset.backgroundSecondary.color) {
                    Task {
                        await viewModel.dispatch(.submitCode(code: code.joined()))
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
            print(viewModel.registrationID)
        }
        .hideKeyboardOnTap()
        .hideKeyboardOnDrag()
    }
}

#Preview {
    let router = AppRouter()
    CodeInputView(router: .init(appRouter: router), email: "", registrationID: "123")
}
