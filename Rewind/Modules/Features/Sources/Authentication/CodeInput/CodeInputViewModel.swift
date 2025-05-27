import Networking
import Domain
import SwiftUI

@MainActor @Observable
final class CodeInputViewModel {
    enum Intent {
        case submitCode(code: String)
    }

    enum CodeState: Equatable {
        case empty
        case loading
        case error(CodeError)
        case ready
    }

    enum CodeError: Error {
        case responseError
        case incorrect

        var errorDescription: String {
            switch self {
            case .responseError:
                return "Something went wrong,\nplease try again"
            case .incorrect:
                return "Your code is incorrect"
            }
        }
    }

    var state: CodeState = .empty
    let router: AuthenticationRouter
    let email: String
    let registrationID: String

    private let backend: NetworkServiceProtocol

    init(router: AuthenticationRouter, email: String, registrationID: String) {
        self.router = router
        self.email = email
        self.registrationID = registrationID
        backend = NetworkService()
    }

    public func dispatch(_ intent: Intent) async {
        switch intent {
        case let .submitCode(code):
            state = .loading
            do {
                let response = try await backend.verifyEmail(registrationID: registrationID, verificationCode: code)
                animateState(to: !response.success ? .error(.incorrect) : .ready )
            } catch {
                animateState(to: .error(.responseError))
            }

            if state == .ready {
                router.navigateToPassword(for: .registration(email: email), registrationID: registrationID)
            }
        }
    }

    func animateState(to state: CodeState) {
        withAnimation(.spring(response: 0.2)) { self.state = state }
    }
}
