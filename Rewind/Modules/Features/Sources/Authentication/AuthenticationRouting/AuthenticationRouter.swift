import SwiftUI

@MainActor
public final class AuthenticationRouter {
    private weak var appRouter: AppRouter?

    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func navigateToEmail(for flow: AuthFlow) {
        appRouter?.navigate(to: .email(flow))
    }

    func navigateToCode(email: String, registrationID: String) {
        appRouter?.navigate(to: .code(email: email, registrationID: registrationID))
    }

    func navigateToPassword(for flow: AuthFlow, registrationID: String? = nil) {
        appRouter?.navigate(to: .password(flow, registrationID: registrationID))
    }

    func navigateToName(email: String, password: String, registrationID: String) {
        appRouter?.navigate(to: .name(email: email, password: password, registrationID: registrationID))
    }

    func navigateToMediaDetails(_ image: UIImage) {
        appRouter?.navigate(to: .mediaDetails(image))
    }

    func navigateToRewind() {
        appRouter?.navigate(to: .rewind)
    }

    func dismiss(by count: Int) {
        appRouter?.pop(by: count)
    }

    func dismiss() {
        appRouter?.pop()
    }
}
