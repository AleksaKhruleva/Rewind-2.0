import SwiftUI
import Domain

@MainActor
public final class RewindRouter {
    private weak var appRouter: AppRouter?

    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func navigateToGallery() {
        appRouter?.navigate(to: .gallery, with: .pushFromBottom)
    }

    func navigateToAccount(user: User) {
        appRouter?.navigate(to: .account(user))
    }

    func navigateToMediaDetails(_ galleryItemId: Int) {
        appRouter?.navigate(to: .mediaDetails(galleryItemId))
    }

    func navigateToMap(galleryItems: [GalleryItem]) {
        appRouter?.navigate(to: .map(galleryItems))
    }

    func navigateToGroup(_ group: Domain.Group) {
        appRouter?.navigate(to: .group(group), with: .pushFromLeft)
    }
}
