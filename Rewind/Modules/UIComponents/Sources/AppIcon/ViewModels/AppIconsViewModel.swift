import SwiftUI

@MainActor @Observable
public final class AppIconsViewModel: Identifiable {
    enum Intent {
        case change(icon: AppIconViewModel)
    }

    var appIcons: [AppIconViewModel]

    public init() {
        self.appIcons = [
            AppIconViewModel(appIcon: "RewindLight", task: "5 days", locked: true),
            AppIconViewModel(appIcon: "RewindPink", task: "5 days", locked: true),
            AppIconViewModel(appIcon: "RewindGradient", task: "20 rewinds", locked: true),
            AppIconViewModel(appIcon: "RewindSakura", task: "2 groups", locked: true),
            AppIconViewModel(appIcon: "RewindLazer", task: "5 invites", locked: false),
            AppIconViewModel(appIcon: "RewindForest", task: "100 rolls", locked: false),
            AppIconViewModel(appIcon: "RewindSea", task: "5 days", locked: false)
        ]
    }

    func dispatch(_ intent: Intent) {
        switch intent {
        case .change(let icon):
            changeAppIcon(icon: icon)
        }
    }

    private func changeAppIcon(icon: AppIconViewModel) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        guard !icon.locked else { return }

        if icon.name == "RewindLight" {
            UIApplication.shared.setAlternateIconName(nil)
        }
        UIApplication.shared.setAlternateIconName(icon.name)

        UserDefaults.standard.set(icon.name, forKey: "appIcon")
        for icon in self.appIcons {
            icon.dispatch(.change)
        }
    }
}
