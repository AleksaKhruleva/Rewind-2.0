import SwiftUI
import UIComponents

public struct MediaDetailsView: View {
    @State var tags = [
        "Ninetendo",
        "XBox",
        "PlayStatio",
        "PlayStation 2",
        "PlayStation 33333333",
        "PlayStation 4"
      ]

    public init() {}
    
    public var body: some View {
        VStack {
            header
            
            VStack(alignment: .leading, spacing: 16) {
                rewind
                
                author
                    .padding(.leading)
                
                tagsView
                
                riskyTable
            }
        }
    }
    
    private var header: some View {
        RewindHeader {
            RewindButton(type: .rightChevron) {}
                .hidden()
        } centerView: {
            Text("Media details")
                .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .bold))
                .foregroundColor(UIComponentsAsset.primaryColor.swiftUIColor)
        } rightView: {
            RewindButton(type: .rightChevron) {}
        }
    }
    
    private var rewind: some View {
        HStack {
            Spacer(minLength: 0)
            Image(uiImage: UIComponentsAsset.avatar.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .cornerRadius(40)
            Spacer(minLength: 0)
        }
    }
    
    private var author: some View {
        AuthorBadgeView(
            image: UIComponentsAsset.media15.image,
            name: "flowykk",
            date: "23.11.2024"
        )
    }
    
    private var tagsView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Tags")
                    .foregroundColor(UIComponentsAsset.tableNameTextColor.swiftUIColor)
                    .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .black))
                    .padding(.leading, 16)
                
                Text("\(tags.count)/5")
                    .foregroundColor(UIComponentsAsset.secondaryColor.swiftUIColor)
                    .modifier(RoundFontModifier(size: 14, weight: .black))
                    .padding(.leading, 4)
                
                Spacer()
                
                Text("autogenerate")
                    .foregroundColor(UIComponentsAsset.pinkColor.swiftUIColor)
                    .modifier(RoundFontModifier(size: 14, weight: .black))
                    .padding(.trailing, 16)
                    .onTapGesture {
                        tags.shuffle()
                    }
            }
            
            TagsView(tags: $tags)
        }
    }
    
    private var riskyTable: some View {
        InformationTable(title: "Risky Zone", data: AccountConstants.risky, isRisky: true)
    }
}

#Preview {
    MediaDetailsView()
}
