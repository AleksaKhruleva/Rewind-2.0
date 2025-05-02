import SwiftUI
import UIComponents

struct QuoteInputView: View {
    @Binding var quote: String
    var onSubmit: () -> Void
    
    @FocusState var isFocused: Bool
    
    public var body: some View {
        VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
            Text("Enter new quote")
                .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
            
            StyledTextField(
                text: $quote,
                placeholder: "quote"
            )
            .multilineTextAlignment(.center)
            .focused($isFocused)
            .onSubmit { onSubmit() }
        }
        .modifier(VStackTopOffsetModifier(topOffsetRatio: AuthConstants.contentTopOffsetRatio))
        .padding(.horizontal)
        .background(UIComponentsAsset.backgroundSecondary.swiftUIColor)
        .onAppear {
            isFocused = true
        }
    }
}
