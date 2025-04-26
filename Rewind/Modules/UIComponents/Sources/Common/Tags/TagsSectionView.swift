import SwiftUI

let maxTags = 5

public struct TagsSectionView: View {
    @Binding var tags: [String]
    
    public init(tags: Binding<[String]>) {
        self._tags = tags
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Tags")
                    .foregroundColor(UIComponentsAsset.tableNameTextColor.swiftUIColor)
                    .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .black))
                    .padding(.leading, 16)
                
                Text("\(tags.count)/\(maxTags)")
                    .foregroundColor(UIComponentsAsset.secondaryColor.swiftUIColor)
                    .modifier(RoundFontModifier(size: 14, weight: .black))
                    .padding(.leading, 4)
                
                Spacer()
                
                Button("autogenerate") {
                    tags.shuffle()
                }
                .buttonStyle(.plain)
                .foregroundColor(UIComponentsAsset.pinkColor.swiftUIColor)
                .modifier(RoundFontModifier(size: 14, weight: .black))
                .padding(.trailing, 16)
                .disabledWithOpacity(tags.isEmpty)
            }
            
            TagsView(tags: $tags)
        }
    }
}
