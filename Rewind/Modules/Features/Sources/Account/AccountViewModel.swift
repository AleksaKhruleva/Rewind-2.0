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
        case deleteImage
        case setImage(UIImage?)
    }

    var showToast: (String) -> Void
    let router: AccountRouter

    private let backend: NetworkServiceProtocol

    var user: User

    var imageBinding: Binding<UIImage?> {
        Binding {
            self.user.image
        } set: { newImage in
            guard let newImage else {
                self.showToast(UIComponentsStrings.Account.Edit.Image.Set.failure)
                return
            }
            self.user.image = newImage
        }
    }

    init(user: User, router: AccountRouter) {
        self.user = user
        self.router = router
        showToast = { _ in }
        backend = NetworkService()
    }

    func dispatch(_ intent: Intent) async {
        switch intent {
        case .signOut:
            if let tokens = Tokens() {
                do {
                    let response = try await backend.logout(tokens: tokens)
                    if response.success {
                        KeychainService.shared.clearAll()
                        router.navigateToWelcome()
                        showToast(UIComponentsStrings.Toast.SignOut.success)
                    } else {
                        showErrorToast()
                    }
                } catch {
                    showErrorToast(for: error)
                }
            }
        case .deleteAccount:
            do {
                let response = try await backend.deleteUser(email: user.email)
                if response.success {
                    KeychainService.shared.clearAll()
                    router.navigateToWelcome()
                    showToast(UIComponentsStrings.Toast.DeleteAccount.success)
                } else {
                    showErrorToast()
                }
            } catch {
                showErrorToast(for: error)
            }
        case .fetchUser:
            do {
                guard let tokens = Tokens() else {
                    router.navigateToWelcome()
                    return
                }
                let response = try await backend.user(tokens: tokens)
                user = response.toUser()
            } catch {
                showErrorToast(for: error)
            }
        case .deleteImage:
            guard user.imageData == nil else {
                showToast(UIComponentsStrings.Account.Edit.Image.Delete.success)
                return
            }
            withAnimation {
                user.imageData = nil
            }
            showToast(UIComponentsStrings.Account.Edit.Image.Delete.success)
        case let .setImage(newImage):
            guard let newImage else {
                showToast(UIComponentsStrings.Account.Edit.Image.Set.failure)
                return
            }
            user.image = newImage
        }
    }

    func set(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
    }

    private func clearLocalData() {
        KeychainService.shared.clearAll()
    }

    private func showErrorToast() {
        showToast(UIComponentsStrings.Toast.error)
    }

    private func showErrorToast(for error: Error) {
        showToast("\(error.localizedDescription) 😨")
    }
}
