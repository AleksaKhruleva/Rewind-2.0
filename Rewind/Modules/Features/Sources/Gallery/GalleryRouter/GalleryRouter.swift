import SwiftUI

@MainActor
public final class GalleryRouter {
    private weak var appRouter: AppRouter?
    
    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }
    
    func navigateToQuote() {
        appRouter?.navigate(to: .quote)
    }
    
    func navigateToMediaDetails(_ image: UIImage) {
        appRouter?.navigate(to: .mediaDetails(image))
    }
}
