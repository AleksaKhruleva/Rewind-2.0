import SwiftUI
import UIComponents

public struct CodeInputView: View {
    @State var viewModel: CodeInputViewModel
    @State private var code: [String] = Array(repeating: "", count: 4)
    
    @Environment(\.dismiss)
    private var dismiss
    
    public init(router: AuthenticationRouter, registrationID: String) {
        viewModel = .init(router: router, registrationID: registrationID)
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color.background.ignoresSafeArea()
            
            RewindHeader {
                RewindButton(type: .leftChevron) { dismiss() }
            }
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text("Enter code from email")
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                CodeInputTextField(code: $code, error: nil) {
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
    CodeInputView(router: .init(appRouter: router), registrationID: "123")
}
