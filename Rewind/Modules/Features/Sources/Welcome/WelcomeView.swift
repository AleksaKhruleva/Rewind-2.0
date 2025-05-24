import SwiftUI
import UIComponents
import Base

public struct WelcomeView: View {
    @State private var textWidth: CGFloat = 0

    private let router: AuthenticationRouter

    public init(router: AuthenticationRouter) {
        self.router = router
    }

    public var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            VStack {
                GradientTitle(text: UIComponentsStrings.App.title, fontSize: 80)
            }
            .modifier(VStackTopOffsetModifier(topOffsetRatio: 0.39))

            VStack(spacing: 12) {
                GradientButton(title: UIComponentsStrings.Welcome.signUp, width: .generic) {
                    router.navigateToEmail(for: .registration())
                }.rewindAccessibilityIdentifier(.auth(.button(.signup)))

                Button {
                    router.navigateToEmail(for: .login())
                } label: {
                    Text(UIComponentsStrings.Welcome.signIn)
                        .modifier(RoundFontModifier(size: 20, foregroundColor: .pinkPrimaryLight))
                        .modifier(MeasureWidthModifier(width: $textWidth))
                }.rewindAccessibilityIdentifier(.auth(.button(.signin)))
            }
            .modifier(VStackTopOffsetModifier(topOffsetRatio: 0.87))
        }
    }
}

#Preview {
    let appRouter = AppRouter()
    WelcomeView(router: .init(appRouter: appRouter))
}
