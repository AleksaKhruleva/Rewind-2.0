import SwiftUI
import UIComponents
import Base
import Networking

@MainActor @Observable
final class AccountNameEditingFlowViewModel {
    enum Intent {
        case submitName(String)
    }

    enum EditingState: Equatable {
        case empty
        case loading
        case error(EditingError)
        case ready
    }

    enum EditingError: Equatable {
        case custom(String?)
        case responseError
    }

    var state: EditingState = .empty
    var isLoading: Bool = false

    var error: String? {
        get {
            if case let .error(editingError) = state {
                switch editingError {
                case .responseError:
                    return UIComponentsStrings.Toast.error
                case let .custom(error):
                    return error
                }
            }
            return nil
        }
        set {
            state = .error(.custom(newValue))
        }
    }

    private let backend: NetworkServiceProtocol

    init() {
        backend = NetworkService()
    }

    func dispatch(_ intent: Intent) async {
        switch intent {
        case let .submitName(name):
            animateState(to: .loading)
            do {
                if let tokens = Tokens() {
                    let response = try await backend.updateUserName(
                        tokens: tokens,
                        name: name
                    )
                    if response.success {
                        animateState(to: .ready)
                    }
                }
            } catch {
                animateState(to: .error(.responseError))
            }
        }
    }

    private func animateState(to state: EditingState) {
        withAnimation(.spring(response: 0.3)) { self.state = state }
    }
}

struct AccountNameEditingFlow: View {
    @State private var viewModel: AccountNameEditingFlowViewModel
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
            placeholder: UIComponentsStrings.GenericInput.NewName.placeholder,
            error: $viewModel.error
        ) { name in
            Task {
                await viewModel.dispatch(.submitName(name))
                if viewModel.state == .ready {
                    afterSuccess?()
                    dismiss()
                }
            }
        }.loadingOverlayIfNeeded(viewModel.state == .loading)
    }
}
