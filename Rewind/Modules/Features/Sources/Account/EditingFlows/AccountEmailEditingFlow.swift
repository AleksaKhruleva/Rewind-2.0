import SwiftUI
import UIComponents
import Networking

@MainActor @Observable
final class AccountEmailEditingFlowViewModel {
    enum Intent {
        case submitPassword(String)
        case submitEmail(String)
        case submitCode(String)
    }

    enum EditingState {
        case password
        case email
        case code
        case ready
    }

    var state: EditingState = .password
    var isLoading: Bool = false

    func dispatch(_ intent: Intent) async {
        switch intent {
        case let .submitPassword(password):
            withAnimation(.easeIn(duration: 0.3)) { isLoading = true }
            print(password)
            await simulateFakeLoad()
            animateState(to: .email)
        case let .submitEmail(email):
            withAnimation(.easeIn(duration: 0.3)) { isLoading = true }
            print(email)
            await simulateFakeLoad()
            animateState(to: .code)
        case let .submitCode(code):
            withAnimation(.easeIn(duration: 0.3)) { isLoading = true }
            print(code)
            await simulateFakeLoad()
            animateState(to: .ready)
        }
    }

    private func animateState(to state: EditingState) {
        withAnimation(.spring(response: 0.3)) {
            self.state = state
            isLoading = false
        }
    }
}

struct AccountEmailEditingFlow: View {
    @State private var viewModel: AccountEmailEditingFlowViewModel
    var onSuccess: (() -> Void)?

    @Environment(\.dismiss)
    private var dismiss

    init(onSuccess: (() -> Void)? = nil) {
        viewModel = AccountEmailEditingFlowViewModel()
        self.onSuccess = onSuccess
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .password:
                GenericInputSheetView(
                    item: .password,
                    title: UIComponentsStrings.GenericInput.YourPassword.title,
                    placeholder: UIComponentsStrings.GenericInput.YourPassword.placeholder
                ) { password in
                    Task {
                        await viewModel.dispatch(.submitPassword(password))
                    }
                }
            case .email:
                GenericInputSheetView(
                    item: .email,
                    title: UIComponentsStrings.GenericInput.NewEmail.title,
                    placeholder: UIComponentsStrings.GenericInput.NewEmail.placeholder
                ) { email in
                    Task {
                        await viewModel.dispatch(.submitEmail(email))
                    }
                }
            case .code:
                GenericInputSheetView(
                    item: .code,
                    title: UIComponentsStrings.GenericInput.VerificationCode.title
                ) { code in
                    Task {
                        await viewModel.dispatch(.submitCode(code))
                        if viewModel.state == .ready {
                            onSuccess?()
                            dismiss()
                        }
                    }
                }
            default:
                EmptyView()
            }
        }.loadingOverlayIfNeeded(viewModel.isLoading)
    }
}

#Preview {
    AccountEmailEditingFlow()
}
