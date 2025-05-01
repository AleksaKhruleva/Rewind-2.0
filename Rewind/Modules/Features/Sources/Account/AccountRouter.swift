@MainActor
public final class AccountRouter {
    private weak var appRouter: AppRouter?
    
    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }
    
    func navigateToWelcome() {
        appRouter?.navigate(to: .welcome)
    }
}
