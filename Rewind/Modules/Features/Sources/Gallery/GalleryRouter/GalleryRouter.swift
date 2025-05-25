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

    func navigateToMediaDetails(_ mediaItem: MediaItem) {
        appRouter?.navigate(to: .mediaDetails(mediaItem))
    }

    func dismiss() {
        appRouter?.pop()
    }
}
