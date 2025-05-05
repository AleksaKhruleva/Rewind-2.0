import SwiftUI
import Networking
import Base
import Domain
import UIComponents

@MainActor @Observable
final class AccountViewModel {
    enum Intent {
        case signOut
        case deleteAccount
        case fetchUser
    }
    
    var showToast: (String) -> Void
    let router: AccountRouter
    
    private let backend: NetworkServiceProtocol
    
    var user: User
    
    init(router: AccountRouter) {
        self.router = router
        showToast = { _ in }
        backend = NetworkService()
        
        guard let user = UserStorage.currentUser else {
            self.user = .init(name: "", email: "")
            return
        }
        self.user = user
    }
    
    func set(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
    }
    
    func dispatch(_ intent: Intent) async {
        switch intent {
        case .signOut:
            if let refreshToken = KeychainService.shared.read(for: .refreshToken),
               let _ = KeychainService.shared.read(for: .accessToken) {
                do {
                    let response = try await backend.logout(refreshToken: refreshToken)
                    if response.success {
                        KeychainService.shared.clearAll()
                        UserStorage.clear()
                        router.navigateToWelcome()
                        showToast(UIComponentsStrings.Toast.SignOut.success)
                    } else {
                        showErrorToast()
                    }
                } catch {
                    showErrorToast()
                }
            }
        case .deleteAccount:
            do {
                let response = try await backend.deleteUser(email: user.email)
                if response.success {
                    KeychainService.shared.clearAll()
                    UserStorage.clear()
                    router.navigateToWelcome()
                    showToast(UIComponentsStrings.Toast.DeleteAccount.success)
                } else {
                    showErrorToast()
                }
            } catch {
                showErrorToast()
            }
        case .fetchUser:
            // temporary
            guard let user = UserStorage.currentUser else {
                user = .init(name: "some flowykk", email: "some@email.ru")
                return
            }
            self.user = user
            if user.name.isEmpty {
                self.user.name = "fake name"
            }
        }
    }
    
    private func clearLocalData() {
        KeychainService.shared.clearAll()
        UserStorage.clear()
    }
    
    private func showErrorToast() {
        showToast(UIComponentsStrings.Toast.error)
    }
}
