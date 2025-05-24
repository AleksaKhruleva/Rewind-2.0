import SwiftUI
import Networking
import Base
import Domain

@MainActor @Observable
final class RewindViewModel {
    enum Intent {
        case fetchUser
    }

    var showToast: (String) -> Void

    var fetchedUser: User?
    var user: User {
        get {
            guard let fetchedUser else {
//                router.navigateToWelcome() // TODO: return when routing is ready
                return User(name: "", email: "")
            }
            return fetchedUser
        }
        set {
            fetchedUser = newValue
        }
    }

    private let backend: NetworkServiceProtocol

    init() {
        showToast = { _ in }
        backend = NetworkService()
    }

    func dispatch(_ intent: Intent) async {
        switch intent {
        case .fetchUser:
            do {
                guard let tokens = Tokens() else {
//                        router.navigateToWelcome() // TODO: return when routing is ready
                    return
                }
                let response = try await backend.user(tokens: tokens)
                user = response.toUser()
            } catch {
                showToast("\(error.localizedDescription) 😨")
            }
        }
    }

    func set(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
    }
}
