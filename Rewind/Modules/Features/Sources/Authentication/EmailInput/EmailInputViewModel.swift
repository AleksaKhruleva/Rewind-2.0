import Networking
import Domain
import SwiftUI

@MainActor @Observable
final class EmailInputViewModel {
    enum EmailState: Equatable {
        case empty
        case loading
        case error(EmailError)
        case ready(registrationID: String)
    }

    enum Intent {
        case submitEmail
    }

    enum EmailError: Error {
        case responseError
        case invalid
        case existing

        var errorDescription: String {
            switch self {
            case .invalid:
                return "Your email in invalid"
            case .responseError:
                return "Something went wrong,\nplease try again"
            case .existing:
                return "This email is already registered"
            }
        }
    }

    var state: EmailState = .empty

    var email: String = ""
    let router: AuthenticationRouter
    let flow: AuthFlow

    private let backend: NetworkServiceProtocol

    init(flow: AuthFlow, router: AuthenticationRouter) {
        self.flow = flow
        self.router = router
        backend = NetworkService()
    }

    func dispatch(_ intent: Intent) async {
        switch intent {
        case .submitEmail:
            guard email.validEmail else {
                animateState(to: .error(.invalid))
                return
            }

            state = .loading
            switch flow {
            case .registration:
                do {
                    let response = try await backend.register(email: email)
                    animateState(to: .ready(registrationID: response.registrationID))
                } catch let httpError as HTTPError where httpError == .conflict {
                    animateState(to: .error(.existing))
                } catch {
                    animateState(to: .error(.responseError))
                }

                if case let .ready(registrationID) = state {
                    router.navigateToCode(email: email, registrationID: registrationID)
                }
            case .login:
                router.navigateToPassword(for: .login(email: email))
            }
        }
    }

    func animateState(to state: EmailState) {
        withAnimation(.spring(response: 0.2)) { self.state = state }
    }
}

extension String {
    fileprivate var validEmail: Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
    }
}
