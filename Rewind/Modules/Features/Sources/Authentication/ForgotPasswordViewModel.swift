import SwiftUI
import Networking
import UIComponents

@MainActor @Observable
final class ForgotPasswordViewModel {
    enum Intent {
        case resetPassword(String)
    }

    var toastMessage: String?
    var isLoading = false
    var message = ""

    private let url: URL
    private let backend: NetworkService
    private weak var router: AppRouter?

    init(url: URL, router: AppRouter) {
        self.url = url
        self.router = router
        backend = NetworkService()
    }

    func dispatch(_ intent: Intent) async {
        switch intent {
        case let .resetPassword(newPassword):
            defer {
                router?.navigate(to: .welcome)
            }
            guard let token = extractToken(from: url) else {
                toastMessage = UIComponentsStrings.Toast.error
                return
            }
            do {
                let response = try await backend.forgotPasswordReset(
                    newPassword: newPassword,
                    token: token
                )

                if response.success {
                    toastMessage = "The password was successfully changed!"
                } else {
                    toastMessage = UIComponentsStrings.Toast.error
                }
            } catch {
                toastMessage = UIComponentsStrings.Toast.error
            }
        }
    }

    private func extractToken(from url: URL) -> String? {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
            return token
        }

        return nil
    }
}
