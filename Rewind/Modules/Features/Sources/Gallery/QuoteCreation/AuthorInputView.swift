import SwiftUI
import UIComponents

struct AuthorInputView: View {
    @Binding var author: String
    var onSubmit: () -> Void

    @FocusState var isFocused: Bool

    public var body: some View {
        VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
            Text(UIComponentsStrings.Quote.Author.title)
                .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))

            StyledTextField(
                text: $author,
                placeholder: UIComponentsStrings.Quote.Author.placeholder
            )
            .multilineTextAlignment(.center)
            .focused($isFocused)
            .onSubmit { onSubmit() }
        }
        .modifier(VStackTopOffsetModifier(topOffsetRatio: AuthConstants.contentTopOffsetRatio))
        .padding(.horizontal)
        .background(Color.backgroundSecondary)
        .onAppear {
            isFocused = true
        }
    }
}
