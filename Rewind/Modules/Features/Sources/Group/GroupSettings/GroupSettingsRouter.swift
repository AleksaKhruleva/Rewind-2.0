import SwiftUI

@MainActor
public final class GroupSettingsRouter {
    private weak var appRouter: AppRouter?

    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func navigateToRewind() {
        appRouter?.navigate(to: .rewind)
    }

    func dismiss() {
        appRouter?.pop()
    }
}
