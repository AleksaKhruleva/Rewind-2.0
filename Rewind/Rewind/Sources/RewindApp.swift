import SwiftUI
import Features
import UIComponents
import Base

@main
struct RewindApp: App {
    @State var toastController = ToastController()
    @State private var appRouter = AppRouter()
    
    var body: some Scene {
        WindowGroup {
            let hasAccessToken = KeychainService.shared.read(for: .accessToken) != nil
            let hasRefreshToken = KeychainService.shared.read(for: .refreshToken) != nil
            let isAuthorized = hasAccessToken && hasRefreshToken
            
            let testingAuth = CommandLine.arguments.contains("-testingAuth")
            
            NavigationStack(path: $appRouter.path) {
                Group {
                    if isAuthorized, !testingAuth {
                        RewindView(router: .init(appRouter: appRouter))
                    } else {
                        WelcomeView(router: .init(appRouter: appRouter))
                    }
                }
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
                    AccountView(router: .init(appRouter: appRouter))
                case .gallery:
                    GalleryView(router: .init(appRouter: appRouter))
                case .quote:
                    QuoteCreationView()
                case let .mediaDetails(image):
                    MediaDetailsView(image: image)
                case let .email(flow):
                    EmailInputView(flow: flow, router: .init(appRouter: appRouter))
                case let .code(registrationID):
                    CodeInputView(router: .init(appRouter: appRouter), registrationID: registrationID)
                case let .password(flow, registrationID):
                    PasswordInputView(flow: flow, router: .init(appRouter: appRouter), registrationID: registrationID)
                case let .name(password, registrationID):
                    NameInputView(router: .init(appRouter: appRouter), password: password, registrationID: registrationID)
                case .rewind:
                    RewindView(router: .init(appRouter: appRouter))
                case .welcome:
                    WelcomeView(router: .init(appRouter: appRouter))
                case .map:
                    RewindsMap()
                }
            }
            .toolbar(.hidden)
        }
    }
}
