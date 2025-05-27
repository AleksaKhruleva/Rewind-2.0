import SwiftUI
import UIComponents
import Domain

public struct MediaDetailsView: View {
    @State private var viewModel: MediaDetailsViewModel
    @State private var tags: [String] = []
    @State private var isTrackPlaying: Bool = false
    private let galleryItem: GalleryItem
    private let router: AppRouter

    @Environment(\.showToast)
    private var showToast

    public init(galleryItem: GalleryItem, router: AppRouter) {
        viewModel = MediaDetailsViewModel()
        self.galleryItem = galleryItem
        self.router = router
    }

    public var body: some View {
        VStack {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    rewind

                    author
                        .padding(.leading)

                    TagsSectionView(tags: $tags)

                    riskyTable
                }
                .ignoresSafeArea()
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .padding(.horizontal, 8)
        }
        .background(Color.background)
        .onAppear {
            viewModel.set(showToast: showToast)
        }
    }

    private var header: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) { router.pop() }
        } centerView: {
            Text(UIComponentsStrings.MediaDetails.title)
                .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .bold))
                .foregroundColor(.textPrimary)
        } rightView: {
            RewindButton(type: .leftChevron).hidden()
        }
    }

    private var rewind: some View {
        MediaContentView(
            mediaItem: galleryItem.memory,
            onSave: {},
            onLike: {},
            onToggleSound: {},
            isTrackPlaying: $isTrackPlaying
        )
    }

    private var author: some View {
        AuthorBadgeView(
            image: UIComponentsAsset.media15.image,
            name: "flowykk",
            date: "23.11.2024",
            track: galleryItem.memory.track
        )
    }

    private var riskyTable: some View {
        InformationTable(title: UIComponentsStrings.MediaDetails.risky, data: [
            ("rectangle.portrait.and.arrow.right.fill", UIComponentsStrings.MediaDetails.delete, nil, {
                Task {
                    await viewModel.dispatch(.deleteMedia(galleryItem))
                    router.pop()
                }
            })
        ], isRisky: true)
    }
}
