import Networking
import Domain
import SwiftUI
import Base
import UIComponents

@MainActor @Observable
final class PasswordInputViewModel {
    enum PasswordState: Equatable {
        case empty
        case loading
        case error(LoginError)
        case ready
    }

    enum Intent {
        case submitPassword
        case dismiss
        case forgotPassword
    }

    enum LoginError: Error {
        case responseError
        case invalid

        var errorDescription: String {
            switch self {
            case .invalid:
                return "Your data in invalid"
            case .responseError:
                return "Something went wrong,\nplease try again"
            }
        }
    }

    var email: String {
        switch flow {
        case .login(let email), .registration(let email):
            return email
        }
    }
    var showNotice = false
    var state: PasswordState = .empty
    var password = ""
    let registrationID: String?
    let router: AuthenticationRouter
    let flow: AuthFlow

    private let backend: NetworkServiceProtocol

    init(flow: AuthFlow, router: AuthenticationRouter, registrationID: String?) {
        self.flow = flow
        self.router = router
        self.registrationID = registrationID
        backend = NetworkService()
    }

    func dispatch(_ intent: Intent) async {
        switch intent {
        case .submitPassword:
            switch flow {
            case let .registration(email):
                router.navigateToName(email: email, password: password, registrationID: registrationID ?? "")
            case let .login(email):
                state = .loading
                do {
                    let response = try await backend.login(email: email, password: password)
                    if !CommandLine.arguments.contains("-testingAuth") {
                        KeychainService.shared.save(response.accessToken, for: .accessToken)
                        KeychainService.shared.save(response.refreshToken, for: .refreshToken)
                    }
                    animateState(to: .ready)
                } catch {
                    animateState(to: .error(.responseError))
                }

                if state == .ready {
                    router.navigateToRewind()
                }
            }
        case .dismiss:
            switch flow {
            case .registration:
                router.dismiss(by: 2)
            case .login:
                router.dismiss(by: 1)
            }
        case .forgotPassword:
            switch flow {
            case .registration:
                print("no no")
            case let .login(email):
                state = .loading
                do {
                    let response = try await backend.forgotPasswordStart(email: email)
                    if response.success {
                        showNotice = true
                        animateState(to: .ready)
                    } else {
                        animateState(to: .error(.responseError))
                    }
                } catch {
                    animateState(to: .error(.responseError))
                }
            }
        }
    }

    func animateState(to state: PasswordState) {
        withAnimation(.spring(response: 0.2)) { self.state = state }
    }
}
