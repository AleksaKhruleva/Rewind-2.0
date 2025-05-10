import SwiftUI

@MainActor @Observable
public final class AppRouter {
    public enum Route: Hashable {
        case welcome
        
        case email(AuthFlow)
        case code(email: String, registrationID: String)
        case password(AuthFlow, registrationID: String?)
        case name(email: String, password: String, registrationID: String)
        
        case rewind
        case map
        
        case account
        case gallery
        case quoteCreation
        case mediaLoading
        case mediaDetails(UIImage)
    }
    
    public var path = NavigationPath()
    
    public init() {}
    
    func navigate(to route: Route) {
        path.append(route)
    }
    
    func pop() {
        path.removeLast()
    }
    
    func pop(by count: Int) {
        path.removeLast(count)
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}
