import SwiftUI
import Domain

@MainActor @Observable
public final class AppIconsViewModel: Identifiable {
    enum Intent {
        case change(icon: AppIconViewModel)
    }

    public var appIcons: [AppIconViewModel]

    public init(with achievements: [Achievement]) {
        appIcons = [
            AppIconViewModel(appIcon: "RewindLight", locked: false),
            AppIconViewModel(appIcon: "RewindPink", locked: false)
        ]
        
        for achievement in achievements {
            appIcons.append(AppIconViewModel(
                appIcon: achievement.icon,
                task: achievement.name,
                locked: !achievement.isUnlocked
            ))
        }
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
