import SwiftUI
import UIComponents

struct QuoteInputView: View {
    @Binding var quote: String
    var onSubmit: () -> Void

    @FocusState var isFocused: Bool

    public var body: some View {
        VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
            Text(UIComponentsStrings.Quote.Quote.title)
                .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))

            StyledTextField(
                text: $quote,
                placeholder: UIComponentsStrings.Quote.Quote.placeholder
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
