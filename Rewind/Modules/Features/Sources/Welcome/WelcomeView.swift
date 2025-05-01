import SwiftUI
import UIComponents
import Base

public struct WelcomeView: View {
    @State private var textWidth: CGFloat = 0
    
    var router: AuthenticationRouter
    
    public init(router: AuthenticationRouter) {
        self.router = router
    }
    
    public var body: some View {
        ZStack {
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
                        .modifier(RoundFontModifier(size: 20, foregroundColor: UIComponentsAsset.lightPinkColor.swiftUIColor))
                        .modifier(MeasureWidthModifier(width: $textWidth))
                }
            }
            .modifier(VStackTopOffsetModifier(topOffsetRatio: 0.87))
        }
        .onAppear {
            print(KeychainService.shared.read(for: .accessToken))
            print(KeychainService.shared.read(for: .refreshToken))
        }
    }
}

#Preview {
    let appRouter = AppRouter()
    WelcomeView(router: .init(appRouter: appRouter))
}
