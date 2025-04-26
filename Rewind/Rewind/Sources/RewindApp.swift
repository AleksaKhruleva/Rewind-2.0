import SwiftUI
import Features
import UIComponents

@main
struct RewindApp: App {
    @State var toastController = ToastController()
    
    var body: some Scene {
        WindowGroup {
            RewindView() // Change only this line if needed! pls! 😌
                .withRewindRouter() // без этого не работает
                .overlay {
                    ToastView(controller: toastController)
                }
                .environment(\.showToast, {
                    toastController.present(with: $0)
                })
        }
    }
}
