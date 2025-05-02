import SwiftUI
import Networking
import Base

@MainActor @Observable
final class AccountViewModel {
    enum Intent {
        case signOut
    }
    
    var showToast: (String) -> Void
    let router: AccountRouter
    
    private let backend: NetworkServiceProtocol
    
    init(router: AccountRouter) {
        self.router = router
        showToast = { _ in }
        backend = NetworkService()
    }
    
    func set(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
    }
    
    func dispatch(_ intent: Intent) async {
        switch intent {
        case .signOut:
            if let refreshToken = KeychainService.shared.read(for: .refreshToken),
               let refreshToken = KeychainService.shared.read(for: .accessToken) {
                do {
                    let response = try await backend.logout(refreshToken: refreshToken)
                    if response.success {
                        KeychainService.shared.clearAll()
                        router.navigateToWelcome()
                    } else {
                        showErrorToast()
                    }
                } catch {
                    showErrorToast()
                }
            }
        }
    }
    
    private func showErrorToast() {
        showToast("Something went wrong, please try again 😩")
    }
}
