import SwiftUI
import Domain

@MainActor @Observable
public final class AppRouter {
    public struct RouteWrapper: Identifiable, Equatable {
        public let id = UUID()
        public let route: Route
        public let transition: TransitionStyle
    }
    
    public enum TransitionStyle {
        case pushFromRight, pushFromLeft, pushFromBottom, none
    }
    
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
        case mediasUploading
        case mediaDetails(UIImage)
    }
    
    public var stack: [RouteWrapper] = []
    
    public init() {}
    
    public func setInitial(_ route: Route) {
        stack = [.init(route: route, transition: .none)]
    }
    
    func navigate(to route: Route, with transition: TransitionStyle = .pushFromRight) {
        stack.append(.init(route: route, transition: transition))
    }
    
    func pop() {
        pop(by: 1)
    }
    
    func pop(by count: Int) {
        guard count > 0, count <= stack.count - 1 else { return }
        stack.removeLast(count)
    }
}
