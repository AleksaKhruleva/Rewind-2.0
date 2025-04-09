import Foundation
import SwiftUI

public class AppIconViewModel: Identifiable, ObservableObject {
    enum Event {
        case change
    }
    
    let name: String
    let task: String
    let needTitle: Bool
    @Published var selected: Bool
    @Published var locked: Bool

    public init(appIcon: String, task: String, locked: Bool = true, needTitle: Bool = true) {
        self.name = appIcon
        self.task = task
        self.locked = locked
        self.needTitle = needTitle
        self.selected = appIcon == UserDefaults.standard.string(forKey: "appIcon") ? true : false
    }
    
    func dispatch(_ event: Event) {
        switch event {
        case .change:
            selected = name == UserDefaults.standard.string(forKey: "appIcon")
        }
    }
}
