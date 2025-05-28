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
        case loadUserImage
        case deleteImage
        case setImage(UIImage?)
    }

    var showToast: (String) -> Void
    let router: AccountRouter

    private let backend: NetworkServiceProtocol

    var user: User
    var userImage: UIImage = DomainAsset.userPlacholder.image

    var imageBinding: Binding<UIImage?> {
        Binding {
            self.userImage
        } set: { newImage in
            guard let newImage else {
                self.showToast(UIComponentsStrings.Account.Edit.Image.Set.failure)
                return
            }
            self.userImage = newImage
        }
    }

    init(user: User, router: AccountRouter) {
        self.user = user
        self.router = router
        showToast = { _ in }
        backend = NetworkService()
    }

    func dispatch(_ intent: Intent, onSuccess: @escaping () -> Void = {}) async {
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
                if let tokens = Tokens() {
                    let response = try await backend.deleteUser(tokens: tokens, email: user.email)
                    if response.success {
                        KeychainService.shared.clearAll()
                        router.navigateToWelcome()
                        showToast(UIComponentsStrings.Toast.DeleteAccount.success)
                    }
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
            print()
//            await dispatch(.setImage(UIImage()))
        case let .setImage(newImage):
            do {
                if let tokens = Tokens(), let newImage {
                    let response = try await backend.updateUserAvatar(tokens: tokens, avatar: newImage)
                    if response.success {
                        showToast(UIComponentsStrings.Account.Edit.Image.Set.success)
                        userImage = newImage
                        onSuccess()
                    }
                }
            } catch {
                showErrorToast(for: error)
            }
        case .loadUserImage:
            await loadUserImage()
        }
    }

    func set(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
    }

    private func loadUserImage() async {
        let image = await ImageProvider.loadOrGetImage(
            for: user.imageURL, .user
        )
        await MainActor.run { [weak self] in
            self?.userImage = image
        }
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
