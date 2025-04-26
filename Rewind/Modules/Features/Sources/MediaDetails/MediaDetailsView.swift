import SwiftUI
import UIComponents

public struct MediaDetailsView: View {
    @State var tags: [String] = []
    var image: UIImage
    
    @Environment(\.dismiss) private var dismiss

    public init(image: UIImage) {
        self.image = image
    }
    
    public var body: some View {
        VStack {
            header
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    rewind
                    
                    author
                        .padding(.leading)
                    
                    tagsView
                    
                    riskyTable
                }
                .ignoresSafeArea()
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .padding(.horizontal, 8)
        }
    }
    
    private var header: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) { dismiss() }
        } centerView: {
            Text("Media details")
                .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .bold))
                .foregroundColor(UIComponentsAsset.primaryColor.swiftUIColor)
        } rightView: {
            RewindButton(type: .leftChevron) {}
                .hidden()
        }
    }
    
    private var rewind: some View {
        Rectangle().toSquare(image, cornerRadius: 40)
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
                    .opacity(tags.isEmpty ? 0.5 : 1)
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
    MediaDetailsView(image: UIComponentsAsset.avatar.image)
}
