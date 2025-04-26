import SwiftUI
import UIComponents

struct AuthorInputView: View {
    @Binding var author: String
    var onSubmit: () -> Void
    
    @FocusState var isFocused: Bool
    
    public var body: some View {
        VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
            Text("Enter quote's author")
                .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
            
            StyledTextField(
                text: $author,
                placeholder: "author"
            )
            .multilineTextAlignment(.center)
            .focused($isFocused)
            .onSubmit { onSubmit() }
        }
        .modifier(VStackTopOffsetModifier(topOffsetRatio: AuthConstants.contentTopOffsetRatio))
        .padding(.horizontal)
        .background(UIComponentsAsset.tableBackgroundColor.swiftUIColor)
        .onAppear {
            isFocused = true
        }
    }
}
