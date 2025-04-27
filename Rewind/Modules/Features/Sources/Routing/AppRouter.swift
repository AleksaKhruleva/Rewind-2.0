import SwiftUI

public final class AppRouter: ObservableObject {
    public enum Route: Hashable {
        case email(AuthFlow)
        case code
        case password(AuthFlow)
        case name
        
        case rewind
        
        case account
        case gallery
        case quote
        case mediaDetails(UIImage)
    }
    
    @Published public var path = NavigationPath()
    
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
