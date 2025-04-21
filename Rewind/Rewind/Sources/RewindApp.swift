import SwiftUI
import Features
import UIComponents

@main
struct RewindApp: App {
    @State var toastController = ToastController()
    
    var body: some Scene {
        WindowGroup {
            AccountView() // Change only this line if needed! pls! 😌
                .overlay {
                    ToastView(controller: toastController)
                }
                .environment(\.showToast, {
                    toastController.present(with: $0)
                })
        }
    }
}
