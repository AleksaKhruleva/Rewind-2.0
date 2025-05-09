import SwiftUI
import Features
import UIComponents
import Base

@main
struct RewindApp: App {
    @StateObject private var coordinator = NavigationCoordinator()
    @State private var toastController = ToastController()
    
    var body: some Scene {
        WindowGroup {
            let hasAccessToken = KeychainService.shared.read(for: .accessToken) != nil
            let hasRefreshToken = KeychainService.shared.read(for: .refreshToken) != nil
            let isAuthorized = hasAccessToken && hasRefreshToken
            let isUserSaved = UserStorage.currentUser != nil
            
            let testingAuth = CommandLine.arguments.contains("-testingAuth")
            
            let initialRoute: AppRouter.Route = (isAuthorized && isUserSaved && !testingAuth) ? .rewind : .rewind
            
            UIKitNavigationContainer(coordinator: coordinator, initialRoute: initialRoute)
                .setupToast(toastController: toastController)
                .environment(\.showToast, {
                    toastController.present(with: $0)
                })
        }
    }
}

struct UIKitNavigationContainer: UIViewControllerRepresentable {
    let coordinator: NavigationCoordinator
    let initialRoute: AppRouter.Route
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        coordinator.start(with: navigationController, initialRoute: initialRoute)
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

extension View {
    fileprivate func setupToast(toastController: ToastController) -> some View {
        self.overlay {
            ToastView(controller: toastController)
        }
    }
}
