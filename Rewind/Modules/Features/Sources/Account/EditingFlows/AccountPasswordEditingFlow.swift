import SwiftUI
import UIComponents
import Networking

// temporary
public func simulateFakeLoad() async {
    do {
        try await Task.sleep(for: .seconds(1))
    } catch {
        print("Ошибочка вышла")
    }
}

@MainActor @Observable
final class AccountPasswordEditingFlowViewModel {
    enum Intent {
        case submitCode(String)
        case submitPassword(String)
    }

    enum EditingState {
        case code
        case password
        case ready
    }

    var state: EditingState = .code
    var isLoading: Bool = false

    func dispatch(_ intent: Intent) async {
        switch intent {
        case let .submitCode(code):
            withAnimation(.easeIn(duration: 0.3)) { isLoading = true }
            print(code)
            await simulateFakeLoad()
            animateState(to: .password)
        case let .submitPassword(password):
            withAnimation(.easeIn(duration: 0.3)) { isLoading = true }
            print(password)
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

struct AccountPasswordEditingFlow: View {
    @State private var viewModel: AccountPasswordEditingFlowViewModel
    var afterSuccess: (() -> Void)?

    @Environment(\.dismiss)
    private var dismiss

    init(afterSuccess: (() -> Void)?) {
        viewModel = AccountPasswordEditingFlowViewModel()
        self.afterSuccess = afterSuccess
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .code:
                GenericInputSheetView(
                    item: .code,
                    title: UIComponentsStrings.GenericInput.VerificationCode.title,
                ) { code in
                    Task {
                        await viewModel.dispatch(.submitCode(code))
                    }
                }
            case .password:
                GenericInputSheetView(
                    item: .password,
                    title: UIComponentsStrings.GenericInput.NewPassword.title,
                    placeholder: UIComponentsStrings.GenericInput.NewPassword.placeholder
                ) { password in
                    Task {
                        await viewModel.dispatch(.submitPassword(password))
                        if viewModel.state == .ready {
                            afterSuccess?()
                            dismiss()
                        }
                    }
                }
            default: EmptyView()
            }
        }.loadingOverlayIfNeeded(viewModel.isLoading)
    }
}
