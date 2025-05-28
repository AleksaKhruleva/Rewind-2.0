import SwiftUI

struct IsTopScreenKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    public var isTopScreen: Bool {
        get { self[IsTopScreenKey.self] }
        set { self[IsTopScreenKey.self] = newValue }
    }
}

struct OnTopAppearModifier: ViewModifier {
    @Environment(\.isTopScreen) private var isTopScreen
    @State private var previousTop = false

    let perform: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                if isTopScreen {
                    perform()
                }
                previousTop = isTopScreen
            }
            .onChange(of: isTopScreen) { _, newValue in
                if newValue && !previousTop {
                    perform()
                }
                previousTop = newValue
            }
    }
}

struct OnTopDisappearModifier: ViewModifier {
    @Environment(\.isTopScreen) private var isTopScreen
    @State private var previousTop = false

    let perform: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                previousTop = isTopScreen
            }
            .onChange(of: isTopScreen) { _, newValue in
                if !newValue && previousTop {
                    perform()
                }
                previousTop = newValue
            }
    }
}
