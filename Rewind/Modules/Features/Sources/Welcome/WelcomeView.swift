import SwiftUI
import UIComponents
import Base

public struct WelcomeView: View {
    @State private var textWidth: CGFloat = 0
    
    let router: AuthenticationRouter
    
    public init(router: AuthenticationRouter) {
        self.router = router
    }
    
    public var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack {
                GradientTitle(text: "Rewind", fontSize: 80)
            }
            .modifier(VStackTopOffsetModifier(topOffsetRatio: 0.39))
            
            VStack(spacing: 12) {
                GradientButton(title: "Sing up", width: 172) {
                    router.navigateToEmail(for: .registration)
                }
                
                Button {
                    router.navigateToEmail(for: .login())
                } label: {
                    Text("Have an account?")
                        .modifier(RoundFontModifier(size: 20, foregroundColor: .pinkPrimaryLight))
                        .modifier(MeasureWidthModifier(width: $textWidth))
                }
            }
            .modifier(VStackTopOffsetModifier(topOffsetRatio: 0.87))
        }
    }
}

#Preview {
    let appRouter = AppRouter()
    WelcomeView(router: .init(appRouter: appRouter))
}
