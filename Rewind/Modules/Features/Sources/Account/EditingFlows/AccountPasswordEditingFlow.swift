import SwiftUI
import UIComponents
import Networking
import Base

@MainActor @Observable
final class AccountPasswordEditingFlowViewModel {
    enum Intent {
        case sendCode
        case submitCode(String)
        case submitPassword(String)
    }
    enum EditingState: Equatable {
        case code
        case password
        case loading
        case error(EditingError)
        case ready
    }

    enum EditingError: Equatable {
        case custom(String?)
        case responseError
        case invalidCode
        case invalidPasswordForamt
    }
    var state: EditingState = .code {
        didSet {
            if state == .password { visibleState = .password }
        }
    }
    var visibleState: EditingState = .code
    var error: String? {
        get {
            if case let .error(editingError) = state {
                switch editingError {
                case .responseError:
                    return UIComponentsStrings.Toast.error
                case .invalidCode:
                    return "Your code is incorrect"
                case .invalidPasswordForamt:
                    return "Your password format is incorrect"
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
        case .sendCode:
            do {
                if let tokens = Tokens() {
                    _ = try await backend.passwordResetStart(tokens: tokens)
                }
            } catch {
                animateState(to: .error(.responseError))
            }
        case let .submitCode(code):
            animateState(to: .loading)
            do {
                if let tokens = Tokens() {
                    let response = try await backend.passwordResetVerify(tokens: tokens, verificationCode: code)
                    if response.success {
                        animateState(to: .password)
                    }
                }
            } catch let httpError as HTTPError where httpError == .badRequest {
                animateState(to: .error(.invalidCode))
            } catch {
                animateState(to: .error(.responseError))
            }
        case let .submitPassword(password):
            animateState(to: .loading)
            do {
                if let tokens = Tokens() {
                    let response = try await backend.passwordResetSet(tokens: tokens, password: password)
                    if response.success {
                        animateState(to: .ready)
                    }
                }
            } catch let httpError as HTTPError where httpError == .badRequest {
                animateState(to: .error(.invalidPasswordForamt))
            } catch {
                animateState(to: .error(.responseError))
            }
        }
    }

    private func animateState(to state: EditingState) {
        withAnimation(.spring(response: 0.3)) { self.state = state }
    }
}

struct AccountPasswordEditingFlow: View {
    @State private var viewModel: AccountPasswordEditingFlowViewModel
    var afterSuccess: (() -> Void)?

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.showToast)
    private var showToast
    init(afterSuccess: (() -> Void)?) {
        viewModel = AccountPasswordEditingFlowViewModel()
        self.afterSuccess = afterSuccess
    }

    var body: some View {
        Group {
            switch viewModel.visibleState {
            case .code:
                GenericInputSheetView(
                    item: .code,
                    title: UIComponentsStrings.GenericInput.VerificationCode.title,
                    error: $viewModel.error
                ) { code in
                    Task {
                        await viewModel.dispatch(.submitCode(code))
                    }
                }
            case .password:
                GenericInputSheetView(
                    item: .password,
                    title: UIComponentsStrings.GenericInput.NewPassword.title,
                    placeholder: UIComponentsStrings.GenericInput.NewPassword.placeholder,
                    error: $viewModel.error
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
        }.onAppear {
            Task { await viewModel.dispatch(.sendCode) }
        }
        .loadingOverlayIfNeeded(viewModel.state == .loading)
    }
}
