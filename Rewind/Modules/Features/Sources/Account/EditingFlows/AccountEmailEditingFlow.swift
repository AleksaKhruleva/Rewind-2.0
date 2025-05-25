import SwiftUI
import UIComponents
import Networking
import Base

@MainActor @Observable
final class AccountEmailEditingFlowViewModel {
    enum Intent {
        case submitPassword(String)
        case submitEmail(String)
        case submitCode(String)
    }

    enum EditingState: Equatable {
        case password
        case email
        case code
        case loading
        case error(EditingError)
        case ready
    }

    enum EditingError: Equatable {
        case custom(String?)
        case responseError
        case invalidPassword
        case existingEmail
    }

    var state: EditingState = .password {
        didSet {
            if state == .email {
                visibleState = .email
            } else if state == .code {
                visibleState = .code
            }
        }
    }
    var visibleState: EditingState = .password

    var error: String? {
        get {
            if case let .error(editingError) = state {
                switch editingError {
                case .responseError:
                    return UIComponentsStrings.Toast.error
                case .invalidPassword:
                    return "Your password is invalid"
                case .existingEmail:
                    return "This email is already registered"
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
        case let .submitPassword(password):
            animateState(to: .loading)
            do {
                if let tokens = Tokens() {
                    let response = try await backend.checkPassword(tokens: tokens, password: password)
                    if response.success {
                        animateState(to: .email)
                    }
                }
            } catch let httpError as HTTPError where httpError == .forbidden {
                animateState(to: .error(.invalidPassword))
            } catch {
                animateState(to: .error(.responseError))
            }
        case let .submitEmail(email):
            animateState(to: .loading)
            do {
                if let tokens = Tokens() {
                    let response = try await backend.emailStartChange(tokens: tokens, email: email)
                    if response.success {
                        animateState(to: .code)
                    }
                }
            } catch let httpError as HTTPError where httpError == .conflict {
                animateState(to: .error(.existingEmail))
            } catch {
                animateState(to: .error(.responseError))
            }
        case let .submitCode(code):
            animateState(to: .loading)
            do {
                if let tokens = Tokens() {
                    let response = try await backend.emailVerifyChange(tokens: tokens, verificationCode: code)
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
            switch viewModel.visibleState {
            case .password:
                GenericInputSheetView(
                    item: .password,
                    title: UIComponentsStrings.GenericInput.YourPassword.title,
                    placeholder: UIComponentsStrings.GenericInput.YourPassword.placeholder,
                    error: $viewModel.error
                ) { password in
                    Task {
                        await viewModel.dispatch(.submitPassword(password))
                    }
                }
            case .email:
                GenericInputSheetView(
                    item: .email,
                    title: UIComponentsStrings.GenericInput.NewEmail.title,
                    placeholder: UIComponentsStrings.GenericInput.NewEmail.placeholder,
                    error: $viewModel.error
                ) { email in
                    Task {
                        await viewModel.dispatch(.submitEmail(email))
                    }
                }
            case .code:
                GenericInputSheetView(
                    item: .code,
                    title: UIComponentsStrings.GenericInput.VerificationCode.title,
                    error: $viewModel.error
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
        }.loadingOverlayIfNeeded(viewModel.state == .loading)
    }
}

#Preview {
    AccountEmailEditingFlow()
}
