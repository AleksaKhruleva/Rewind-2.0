import SwiftUI
import Domain

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

    func navigateToMediaDetails(_ galleryItemId: Int) {
        appRouter?.navigate(to: .mediaDetails(galleryItemId))
    }

    func dismiss() {
        appRouter?.pop()
    }
}
