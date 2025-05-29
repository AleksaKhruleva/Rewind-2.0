import SwiftUI
import Domain

let maxTags = 5

public struct TagsSectionView: View {
    @Binding var tags: [MediaTag]
    var useInvertedColors: Bool
    var onTagAdd: ((MediaTag) -> Void)?
    var onTagDelete: ((MediaTag) -> Void)?

    public init(
        tags: Binding<[MediaTag]>,
        useInvertedColors: Bool = false,
        onTagAdd: ((MediaTag) -> Void)? = nil,
        onTagDelete: ((MediaTag) -> Void)? = nil
    ) {
        self._tags = tags
        self.useInvertedColors = useInvertedColors
        self.onTagAdd = onTagAdd
        self.onTagDelete = onTagDelete
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

//                Button(UIComponentsStrings.Tags.Section.autogenerate) {
//                    withAnimation { tags.shuffle() }
//                }
//                .buttonStyle(.plain)
//                .foregroundColor(.pinkPrimary)
//                .modifier(RoundFontModifier(size: 14, weight: .black))
//                .padding(.trailing, 16)
//                .disabledWithOpacity(tags.isEmpty)
            }

            TagsView(
                tags: $tags,
                useInvertedColors: useInvertedColors,
                onTagAdd: onTagAdd ?? { tags.append($0) },
                onTagDelete: onTagDelete ?? { tagToDelete in
                    tags.removeAll { $0.tag == tagToDelete.tag }
                }
            )
        }
    }
}
