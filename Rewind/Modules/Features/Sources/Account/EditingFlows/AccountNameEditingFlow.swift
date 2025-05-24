import SwiftUI
import UIComponents
import Base
import Networking

@MainActor @Observable
final class AccountNameEditingFlowViewModel {
    enum Intent {
        case submitName(String)
    }
    
    enum EditingState {
        case empty
        case ready
    }
    
    enum EditingError {
        
    }
    
    var state: EditingState = .empty
    var isLoading: Bool = false
    
    func dispatch(_ intent: Intent) async {
        switch intent {
        case let .submitName(name):
            withAnimation(.easeIn(duration: 0.3)) { isLoading = true }
            await simulateFakeLoad()
            state = .ready
        }
    }
}

struct AccountNameEditingFlow: View {
    @State var viewModel: AccountNameEditingFlowViewModel
    var afterSuccess: (() -> Void)?
    
    @Environment(\.dismiss)
    private var dismiss
    
    init(afterSuccess: (() -> Void)? = nil) {
        viewModel = AccountNameEditingFlowViewModel()
        self.afterSuccess = afterSuccess
    }
    
    var body: some View {
        GenericInputSheetView(
            item: .name,
            title: UIComponentsStrings.GenericInput.NewName.title,
            placeholder: UIComponentsStrings.GenericInput.NewName.placeholder
        ) { name in
            Task {
                await viewModel.dispatch(.submitName(name))
                if viewModel.state == .ready {
                    afterSuccess?()
                    dismiss()
                }
            }
        }.loadingOverlayIfNeeded(viewModel.isLoading)
    }
}
