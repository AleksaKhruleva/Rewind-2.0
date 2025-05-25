import SwiftUI

let maxTags = 5

public struct TagsSectionView: View {
    @Binding var tags: [String]
    var useInvertedColors: Bool

    public init(tags: Binding<[String]>, useInvertedColors: Bool = false) {
        self._tags = tags
        self.useInvertedColors = useInvertedColors
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(UIComponentsStrings.Tags.Section.title)
                    .foregroundColor(.textSecondary)
                    .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .black))
                    .padding(.leading, 16)

                Text("\(tags.count)/\(maxTags)")
                    .foregroundColor(.textTertiary)
                    .modifier(RoundFontModifier(size: 14, weight: .black))
                    .padding(.leading, 4)

                Spacer()

                Button(UIComponentsStrings.Tags.Section.autogenerate) {
                    withAnimation { tags.shuffle() }
                }
                .buttonStyle(.plain)
                .foregroundColor(.pinkPrimary)
                .modifier(RoundFontModifier(size: 14, weight: .black))
                .padding(.trailing, 16)
                .disabledWithOpacity(tags.isEmpty)
            }

            TagsView(tags: $tags, useInvertedColors: useInvertedColors)
        }
    }
}
