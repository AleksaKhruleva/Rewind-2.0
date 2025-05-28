import SwiftUI
import Domain
import Base
import UIComponents

struct RewindsListCell: View {
    var rewind: GalleryItem

    @State private var userImage: UIImage = DomainAsset.groupPlaceholder.image

    var body: some View {
        HStack {
            SquareAsyncMedia(url: rewind.memory.mediaURL, type: .image, cornerRadius: 20)
                .frame(90)
                .padding(.trailing, 16)

            VStack(alignment: .leading) {
                HStack(spacing: 12) {
                    Text(UIComponentsStrings.Map.RewindsList.author)
                        .modifier(RoundFontModifier(size: 17, weight: .bold))

                    HeaderBadgeView(
                        image: userImage,
                        text: rewind.memory.username
                    )
                    .lineLimit(1)
                }

                Text(rewind.memory.createdAt.description)
                    .modifier(RoundFontModifier(size: 15, foregroundColor: .textTertiary))
            }

            Spacer(minLength: 0)
        }
        .task {
            await fetchImage()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    private func fetchImage() async {
        let image = await ImageProvider.loadOrGetImage(
            for: rewind.memory.userImage?.absoluteString, .group
        )
        userImage = image
    }
}
