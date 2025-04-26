import SwiftUI
import UIComponents

public struct CodeInputView: View {
    @State private var code: [String] = Array(repeating: "", count: 4)
    @State private var focusedField: Int = 0
    
    public init() { }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            BackButton(direction: .left) {
                // TODO: do something later
            }
            .modifier(BackButtonPositionModifier())
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text("Enter code from email")
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                CodeInputTextField(code: $code, error: nil) { _ in
                    // TODO: Something when code is filled
                }
            }
            .modifier(VStackTopOffsetModifier(topOffsetRatio: AuthConstants.contentTopOffsetRatio))
        }
        .hideKeyboardOnTap()
        .hideKeyboardOnDrag()
    }
}

#Preview {
    CodeInputView()
}
