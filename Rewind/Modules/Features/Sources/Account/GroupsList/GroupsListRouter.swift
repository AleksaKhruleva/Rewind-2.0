import SwiftUI
import Domain

@MainActor
public final class GroupsListRouter {
    private weak var appRouter: AppRouter?

    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func dismiss() {
        appRouter?.pop()
    }
}
