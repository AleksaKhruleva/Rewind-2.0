import SwiftUI

struct TagsView: View {
    @Binding var tags: [String]
    @State private var totalHeight = CGFloat.zero
    @State private var tagInputPresented = false

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
                placeholder: UIComponentsStrings.GenericInput.NewTag.placeholder
            ) { tag in
                tags.append(tag)
                tagInputPresented = false
            }
        }
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        var lastWidth: CGFloat = 0
        var lastHeight: CGFloat = 0
        
        return ZStack(alignment: .topLeading) {
            ForEach(self.tags, id: \.self) { tag in
                self.item(for: tag)
                    .padding([.vertical, .trailing], 4)
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > geometry.size.width)
                        {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if let lastTag = self.tags.last, tag == lastTag {
                            lastWidth = -abs(width - d.width)
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { d in
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
                .background(Color.backgroundSecondary)
                .clipShape(Circle())
                .padding([.vertical, .trailing], 4)
                .alignmentGuide(.leading) { d in
                    if (abs(lastWidth - d.width) > geometry.size.width) {
                        lastWidth = 0
                        lastHeight -= d.height
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

    private func item(for text: String) -> some View {
        HStack {
            Text(text)
                .foregroundColor(.textPrimary)
                .modifier(RoundFontModifier(size: 16, weight: .bold))
                .padding(.leading, 8)

            Image(systemName: "minus")
                .font(.system(size: 16, weight: .black))
                .frame(width: 30, height: 30)
                .background(.white)
                .clipShape(Circle())
                .onTapGesture {
                    withAnimation {
                        tags.removeAll { $0 == text }
                    }
                }
        }
        .padding(4)
        .background(Color.backgroundSecondary)
        .cornerRadius(20)
    }
}

#Preview {
    TagsView(tags: Binding.constant([
        "Ninetendo",
        "XBox",
        "PlayStatio",
        "PlayStation 2",
        "PlayStation 4ddd"
      ]))
}
