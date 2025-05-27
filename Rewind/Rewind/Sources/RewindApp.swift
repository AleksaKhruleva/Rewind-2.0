import SwiftUI
import AVFAudio
import Features
import UIComponents
import Base
import Domain

@main
struct RewindApp: App {
    @State private var toastController = ToastController()
    @State private var appRouter = AppRouter()
    @State private var pendingLink: IdentifiableURL?

    init() {
        setupAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            let hasTokens = Tokens() != nil
            let testingAuth = CommandLine.arguments.contains("-testingAuth")

            RootView(router: appRouter)
                .onAppear {
                    let initial: AppRouter.Route = (hasTokens && !testingAuth) ? .rewind : .welcome
                    appRouter.setInitial(initial)
                }
                .setupToast(toastController: toastController)
                .environment(\.showToast, {
                    toastController.present(with: $0)
                })
                .onOpenURL { url in
                    print("here")
                    if hasTokens && !testingAuth {
                        pendingLink = IdentifiableURL(url)
                    } else {
                        toastController.present(with: "You need to log in to join the group!")
                    }
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    if let url = userActivity.webpageURL {
                        if hasTokens && !testingAuth {
                            pendingLink = IdentifiableURL(url)
                        } else {
                            toastController.present(with: "You need to log in to join the group!")
                        }
                    }
                }
                .fullScreenCover(item: $pendingLink) { link in
                    LinkProcessingView(
                        url: link.url,
                        router: appRouter,
                        dismiss: { message in
                            toastController.present(with: message)
                            pendingLink = nil
                        }
                    )
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
