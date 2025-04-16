import SwiftUI

struct ShowToast: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: (String) -> Void = { _ in }
}

extension EnvironmentValues {
    public var showToast: (String) -> Void {
        get { self[ShowToast.self] }
        set { self[ShowToast.self] = newValue }
    }
}
