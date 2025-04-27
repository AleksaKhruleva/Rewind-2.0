import SwiftUI
import UIComponents

public struct CodeInputView: View {
    @State private var code: [String] = Array(repeating: "", count: 4)
    
    var router: AuthenticationRouter
    
    @Environment(\.dismiss)
    private var dismiss
    
    public init(router: AuthenticationRouter) {
        self.router = router
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            RewindHeader {
                RewindButton(type: .leftChevron) { dismiss() }
            }
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text("Enter code from email")
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                CodeInputTextField(code: $code, error: nil) {
                    router.navigateToPassword(for: .registration)
                }
            }
            .modifier(VStackTopOffsetModifier(topOffsetRatio: AuthConstants.contentTopOffsetRatio))
        }
        .hideKeyboardOnTap()
        .hideKeyboardOnDrag()
    }
}

#Preview {
    let router = AppRouter()
    CodeInputView(router: .init(appRouter: router))
}
