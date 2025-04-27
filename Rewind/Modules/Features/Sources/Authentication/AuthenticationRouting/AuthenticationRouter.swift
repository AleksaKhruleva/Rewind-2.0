import SwiftUI

public final class AuthenticationRouter {
    private weak var appRouter: AppRouter?
    
    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }
    
    func navigateToEmail(for flow: AuthFlow) {
        appRouter?.navigate(to: .email(flow))
    }
    
    func navigateToCode() {
        appRouter?.navigate(to: .code)
    }
    
    func navigateToPassword(for flow: AuthFlow) {
        appRouter?.navigate(to: .password(flow))
    }
    
    func navigateToName() {
        appRouter?.navigate(to: .name)
    }
    
    func navigateToMediaDetails(_ image: UIImage) {
        appRouter?.navigate(to: .mediaDetails(image))
    }
    
    func navigateToRewind() {
        appRouter?.navigate(to: .rewind)
    }
    
    func dismiss(by count: Int) {
        appRouter?.pop(by: count)
    }
}
