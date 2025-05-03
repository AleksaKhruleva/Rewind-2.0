import SwiftUI

public struct TagInputView: View {
    private var onSubmit: (String) -> Void
    
    @State private var tag: String = ""
    @FocusState private var isFocused: Bool
    
    @Environment(\.dismiss)
    private var dismiss
    
    public init(onSubmit: @escaping (String) -> Void) {
        self.onSubmit = onSubmit
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
            Text(UIComponentsStrings.Tags.title)
                .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
            
            StyledTextField(
                text: $tag,
                placeholder: UIComponentsStrings.Tags.placeholder
            )
            .multilineTextAlignment(.center)
            .focused($isFocused)
            .onSubmit {
                onSubmit(tag)
                dismiss()
            }
        }
        .modifier(VStackTopOffsetModifier(topOffsetRatio: AuthConstants.contentTopOffsetRatio))
        .background(Color.backgroundSecondary)
        .onAppear {
            isFocused = true
        }
    }
}
