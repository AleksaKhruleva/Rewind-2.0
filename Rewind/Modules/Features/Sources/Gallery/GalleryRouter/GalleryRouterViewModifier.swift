import SwiftUI

struct GalleryRouterViewModifier: ViewModifier {
    typealias Route = GalleryRouter.GalleryRoute
    
    @State private var router = GalleryRouter()
    
    private func routeView(for route: Route) -> some View {
        Group {
            switch route {
            case let .mediaDetails(image):
                MediaDetailsView(image: image)
            case .quote:
                QuoteCreationView()
            }
        }
        .toolbar(.hidden)
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
    func withGalleryRouter() -> some View {
        modifier(GalleryRouterViewModifier())
    }
}
