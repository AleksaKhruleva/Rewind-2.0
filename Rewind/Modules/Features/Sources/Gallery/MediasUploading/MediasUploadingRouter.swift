@MainActor
public final class MediasUploadingRouter {
    private weak var appRouter: AppRouter?

    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func dismiss() {
        appRouter?.pop()
    }
}
