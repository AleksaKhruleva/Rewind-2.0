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
    }

    enum LoginError: Error {
        case responseError
        case invalid

        var errorDescription: String {
            switch self {
            case .invalid:
                return "Your data in invalid"
            case .responseError:
                return "Something went worng,\nplease try again"
            }
        }
    }

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
        }
    }

    func animateState(to state: PasswordState) {
        withAnimation(.spring(response: 0.2)) { self.state = state }
    }
}
