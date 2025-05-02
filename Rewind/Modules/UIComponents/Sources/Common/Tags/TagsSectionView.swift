import SwiftUI

let maxTags = 5

public struct TagsSectionView: View {
    @Binding var tags: [String]
    
    public init(tags: Binding<[String]>) {
        self._tags = tags
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tags")
                    .foregroundColor(.textSecondary)
                    .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .black))
                    .padding(.leading, 16)
                
                Text("\(tags.count)/\(maxTags)")
                    .foregroundColor(.textTertiary)
                    .modifier(RoundFontModifier(size: 14, weight: .black))
                    .padding(.leading, 4)
                
                Spacer()
                
                Button("autogenerate") {
                    withAnimation { tags.shuffle() }
                }
                .buttonStyle(.plain)
                .foregroundColor(.pinkPrimary)
                .modifier(RoundFontModifier(size: 14, weight: .black))
                .padding(.trailing, 16)
                .disabledWithOpacity(tags.isEmpty)
            }
            
            TagsView(tags: $tags)
        }
    }
}
