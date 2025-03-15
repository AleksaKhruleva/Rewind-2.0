import SwiftUI

public class AppIconsViewModel: ObservableObject, Identifiable {
    enum Intent {
        case change(icon: AppIconViewModel)
    }
    
    @Published var appIcons: [AppIconViewModel]
    
    public init() {
        self.appIcons = [
            AppIconViewModel(appIcon: "RewindLight", task: "5 days", locked: false),
            AppIconViewModel(appIcon: "RewindPink", task: "5 days", locked: false),
            AppIconViewModel(appIcon: "RewindGradient", task: "20 rewinds", locked: false),
            AppIconViewModel(appIcon: "RewindSakura", task: "2 groups", locked: false),
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
    
    func changeAppIcon(icon: AppIconViewModel) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        guard !icon.locked else { return }

        UIApplication.shared.setAlternateIconName(icon.name) { [weak self] error in
            guard let self else { return }
            guard error == nil else {
                print("Ошибка смены иконки: \(error!.localizedDescription) \(icon.name)")
                return
            }
            
            UserDefaults.standard.set(icon.name, forKey: "appIcon")
            for icon in self.appIcons {
                icon.dispatch(.change)
            }
            print("Иконка успешно изменена на \(icon.name)")
        }
    }
}
