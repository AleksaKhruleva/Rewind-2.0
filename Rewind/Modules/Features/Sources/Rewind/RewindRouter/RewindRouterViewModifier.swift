import SwiftUI

struct RewindRouterViewModifier: ViewModifier {
    typealias Route = RewindRouter.Route
    
    @State private var router = RewindRouter()
    
    private func routeView(for route: Route) -> some View {
        Group {
            switch route {
            case let .mediaDetails(image):
                MediaDetailsView(image: image)
            case .account:
                AccountView()
            case .gallery:
                GalleryView()
                    .withGalleryRouter()
            }
        }
    }
    
    func body(content: Content) -> some View {
        NavigationStack(path: $router.path) {
            content
                .environment(router)
                .navigationDestination(for: Route.self) { route in
                    routeView(for: route)
                }
        }
    }
}

public extension View {
    func withRewindRouter() -> some View {
        modifier(RewindRouterViewModifier())
    }
}
