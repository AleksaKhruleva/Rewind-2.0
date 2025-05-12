import Domain
import SwiftUI

@MainActor
public final class MediasUploadingRouter {
    private weak var appRouter: AppRouter?
    
    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }
    
    func navigateToMediaSettings(media: LoadedMedia) {
        appRouter?.navigate(to: .mediaLoadingSettings(media))
    }
}
