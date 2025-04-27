import SwiftUI
import UIComponents

public struct NameInputView: View {
    @State private var name: String = ""
    @FocusState private var isFocused: Bool
    
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
                Text("What's your name?")
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                StyledTextField(
                    text: $name,
                    placeholder: "name"
                )
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .onSubmit {
                    router.navigateToRewind()
                }
            }
            .modifier(VStackTopOffsetModifier(topOffsetRatio: AuthConstants.contentTopOffsetRatio))
        }
        .onAppear {
            isFocused = true
        }
        .hideKeyboardOnTap()
        .hideKeyboardOnDrag()
    }
}

#Preview {
    let router = AppRouter()
    NameInputView(router: .init(appRouter: router))
}
