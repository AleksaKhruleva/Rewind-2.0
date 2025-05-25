import SwiftUI

@MainActor
public final class GalleryRouter {
    private weak var appRouter: AppRouter?

    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func navigateToQuoteCreation() {
        appRouter?.navigate(to: .quoteCreation)
    }

    func navigateToMediasUploading() {
        appRouter?.navigate(to: .mediasUploading)
    }

    func navigateToMediaDetails(_ image: UIImage) {
        appRouter?.navigate(to: .mediaDetails(image))
    }

    func dismiss() {
        appRouter?.pop()
    }
}
