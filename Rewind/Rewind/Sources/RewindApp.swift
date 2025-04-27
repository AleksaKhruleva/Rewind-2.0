import SwiftUI
import Features
import UIComponents

@main
struct RewindApp: App {
    @State var toastController = ToastController()
    @StateObject private var appRouter = AppRouter()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $appRouter.path) {
                WelcomeView(router: .init(appRouter: appRouter))
//                RewindView(router: .init(appRouter: appRouter))
                    .setUpNavigation(appRouter: appRouter)
            }
            .setupToast(toastController: toastController)
            .environment(\.showToast, {
                toastController.present(with: $0)
            })
        }
    }
}

extension View {
    fileprivate func setupToast(toastController: ToastController) -> some View {
        self.overlay {
            ToastView(controller: toastController)
        }
    }
    
    fileprivate func setUpNavigation(appRouter: AppRouter) -> some View {
        self.navigationDestination(for: AppRouter.Route.self) { route in
            Group {
                switch route {
                case .account:
                    AccountView()
                case .gallery:
                    GalleryView(router: .init(appRouter: appRouter))
                case .quote:
                    QuoteCreationView()
                case let .mediaDetails(image):
                    MediaDetailsView(image: image)
                case let .email(flow):
                    EmailInputView(flow: flow, router: .init(appRouter: appRouter))
                case .code:
                    CodeInputView(router: .init(appRouter: appRouter))
                case let .password(flow):
                    PasswordInputView(flow: flow, router: .init(appRouter: appRouter))
                case .name:
                    NameInputView(router: .init(appRouter: appRouter))
                case .rewind:
                    RewindView(router: .init(appRouter: appRouter))
                }
            }
            .toolbar(.hidden)
        }
    }
}
