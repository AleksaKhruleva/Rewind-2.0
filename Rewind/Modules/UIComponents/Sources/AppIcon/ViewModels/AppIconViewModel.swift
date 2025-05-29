import Foundation
import SwiftUI

@MainActor @Observable
public final class AppIconViewModel: Identifiable {
    enum Event {
        case change
    }

    let name: String
    let task: String?
    var selected: Bool
    var locked: Bool

    public init(appIcon: String, task: String? = nil, locked: Bool = true) {
        self.name = appIcon
        self.task = task
        self.locked = locked
        self.selected = appIcon == UserDefaults.standard.string(forKey: "appIcon") ? true : false
    }

    func dispatch(_ event: Event) {
        switch event {
        case .change:
            selected = name == UserDefaults.standard.string(forKey: "appIcon")
        }
    }
}
