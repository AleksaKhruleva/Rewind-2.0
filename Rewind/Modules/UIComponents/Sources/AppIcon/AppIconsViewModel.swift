import SwiftUI

public class AppIconsViewModel: ObservableObject {
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
}
