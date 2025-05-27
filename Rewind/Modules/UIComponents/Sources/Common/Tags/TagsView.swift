import SwiftUI
import Domain

struct TagsView: View {
    @Binding var tags: [MediaTag]
    @State private var totalHeight: CGFloat
    @State private var tagInputPresented: Bool
    var useInvertedColors: Bool
    var onTagAdd: ((MediaTag) -> Void)?
    var onTagDelete: ((MediaTag) -> Void)?

    init(
        tags: Binding<[MediaTag]>,
        totalHeight: Double = CGFloat.zero,
        tagInputPresented: Bool = false,
        useInvertedColors: Bool,
        onTagAdd: ((MediaTag) -> Void)?,
        onTagDelete: ((MediaTag) -> Void)?
    ) {
        self._tags = tags
        self.totalHeight = totalHeight
        self.tagInputPresented = tagInputPresented
        self.useInvertedColors = useInvertedColors
        self.onTagAdd = onTagAdd
        self.onTagDelete = onTagDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
            .frame(height: totalHeight)
        }
        .sheet(isPresented: $tagInputPresented) {
            GenericInputSheetView(
                item: .tag,
                title: UIComponentsStrings.GenericInput.NewTag.title,
                placeholder: UIComponentsStrings.GenericInput.NewTag.placeholder,
                error: .constant(nil) // TODO: Use real data
            ) { tag in
                onTagAdd?(MediaTag(tag: tag))
                tagInputPresented = false
            }
        }
    }

    // swiftlint:disable function_body_length
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        var lastWidth: CGFloat = 0
        var lastHeight: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(self.tags) { tag in
                self.item(for: tag.tag)
                    .padding([.vertical, .trailing], 4)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height
                        }
                        let result = width
                        if let lastTag = self.tags.last, tag == lastTag {
                            lastWidth = -abs(width - dimension.width)
                            width = 0
                        } else {
                            width -= dimension.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if let lastTag = self.tags.last, tag == lastTag {
                            lastHeight = height
                            height = 0
                        }
                        return result
                    }
            }

            Image(systemName: "plus")
                .font(.system(size: 18, weight: .black))
                .frame(width: 38, height: 38)
                .background(useInvertedColors ? Color.background : Color.backgroundSecondary)
                .foregroundColor(Color.textPrimary)
                .clipShape(Circle())
                .padding([.vertical, .trailing], 4)
                .alignmentGuide(.leading) { dimension in
                    if abs(lastWidth - dimension.width) > geometry.size.width {
                        lastWidth = 0
                        lastHeight -= dimension.height
                    }
                    return lastWidth
                }
                .alignmentGuide(.top) { _ in return lastHeight }
                .onTapGesture {
                    tagInputPresented = true
                }
                .disabledWithOpacity(tags.count >= maxTags)
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            return proxy.size
        } action: { newSize in
            withAnimation {
                totalHeight = newSize.height
            }
        }
    }
    // swiftlint:enable function_body_length

    private func item(for text: String) -> some View {
        HStack {
            Text(text)
                .foregroundColor(.textPrimary)
                .modifier(RoundFontModifier(size: 16, weight: .bold))
                .padding(.leading, 8)

            Image(systemName: "minus")
                .font(.system(size: 16, weight: .black))
                .frame(width: 30, height: 30)
                .background(useInvertedColors ? Color.backgroundSecondary : Color.background)
                .foregroundColor(Color.textPrimary)
                .clipShape(Circle())
                .onTapGesture {
                    withAnimation {
                        onTagDelete?(MediaTag(tag: text))
                    }
                }
        }
        .padding(4)
        .background(useInvertedColors ? Color.background : Color.backgroundSecondary)
        .cornerRadius(20)
    }
}
