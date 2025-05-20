import SwiftUI
import AVFAudio
import Features
import UIComponents
import Base

@main
struct RewindApp: App {
    @State private var toastController = ToastController()
    @State private var appRouter = AppRouter()
    
    init() {
        setupAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            let hasAccessToken = KeychainService.shared.read(for: .accessToken) != nil
            let hasRefreshToken = KeychainService.shared.read(for: .refreshToken) != nil
            let isAuthorized = hasAccessToken && hasRefreshToken
            let isUserSaved = UserStorage.currentUser != nil
            
            let testingAuth = CommandLine.arguments.contains("-testingAuth")
            
            RootView(router: appRouter)
                .onAppear {
                    let initial: AppRouter.Route = (isAuthorized && isUserSaved && !testingAuth) ? .rewind : .welcome
                    appRouter.setInitial(initial)
                }
                .setupToast(toastController: toastController)
                .environment(\.showToast, {
                    toastController.present(with: $0)
                })
                .onOpenURL { url in
                    print("Universal Link received: \(url)")
                }
        }
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Ошибка настройки аудиосессии: \(error)")
        }
    }
}

extension View {
    fileprivate func setupToast(toastController: ToastController) -> some View {
        self.overlay {
            ToastView(controller: toastController)
        }
    }
}
