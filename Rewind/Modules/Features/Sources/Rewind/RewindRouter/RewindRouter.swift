import SwiftUI

@MainActor
public final class RewindRouter {
    private weak var appRouter: AppRouter?
    
    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }
    
    func navigateToGallery() {
        appRouter?.navigate(to: .gallery, with: .pushFromBottom)
    }
    
    func navigateToAccount() {
        appRouter?.navigate(to: .account)
    }
    
    func navigateToMediaDetails(_ image: UIImage) {
        appRouter?.navigate(to: .mediaDetails(image))
    }
    
    func navigateToMap() {
        appRouter?.navigate(to: .map)
    }
    
    func navigateToGroup() {
        appRouter?.navigate(to: .group, with: .pushFromLeft)
    }
}
