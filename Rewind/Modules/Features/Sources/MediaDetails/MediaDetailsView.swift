import SwiftUI
import UIComponents
import Domain

public struct MediaDetailsView: View {
    @State private var viewModel: MediaDetailsViewModel
    @State private var galleryItemId: Int
    private let router: AppRouter

    @Environment(\.showToast)
    private var showToast

    public init(galleryItemId: Int, router: AppRouter) {
        viewModel = MediaDetailsViewModel()
        self.galleryItemId = galleryItemId
        self.router = router
    }

    public var body: some View {
        VStack {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    rewind

                    author

                    TagsSectionView(tags: $viewModel.tags) { tag in
                        Task {
                            await viewModel.dispatch(.addTag(tag.tag)) {
                                viewModel.tags.append(tag)
                            }
                        }
                    } onTagDelete: { tag in
                        Task {
                            await viewModel.dispatch(.deleteTag(tag.tag)) {
                                withAnimation {
                                    viewModel.tags.removeAll { $0.tag == tag.tag }
                                }
                            }
                        }
                    }

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
            Task {
                await viewModel.dispatch(.fetchMemory(galleryItemId))
            }
            viewModel.set(showToast: showToast)
        }
    }

    private var header: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) {
                Task {
                    await viewModel.dispatch(.killPlayer)
                }
                router.pop()
            }
        } centerView: {
            Text(UIComponentsStrings.MediaDetails.title)
                .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .bold))
                .foregroundColor(.textPrimary)
        } rightView: {
            RewindButton(type: .leftChevron).hidden()
        }
    }

    @ViewBuilder
    private var rewind: some View {
        if let galleryItem = viewModel.galleryItem {
            MediaContentView(
                galleryItem: galleryItem,
                onLike: { liked in
                    Task {
                        await viewModel.dispatch(liked ? .unlikeMedia : .likeMedia)
                    }
                },
                onToggleSound: {
                    Task {
                        await viewModel.dispatch(.toggleTrackPlaying)
                    }
                },
                isTrackPlaying: $viewModel.isTrackPlaying,
                isVideoPlaying: $viewModel.isVideoPlaying
            )
        }
    }

    @ViewBuilder
    private var author: some View {
        if let galleryItem = viewModel.galleryItem {
            AuthorBadgeView(
                imageURL: galleryItem.memory.userImage,
                name: galleryItem.memory.username,
                date: galleryItem.memory.createdAt,
                track: galleryItem.memory.lightTrack
            )
        }
    }

    private var riskyTable: some View {
        InformationTable(title: UIComponentsStrings.MediaDetails.risky, data: [
            ("rectangle.portrait.and.arrow.right.fill", UIComponentsStrings.MediaDetails.delete, nil, {
                Task {
                    await viewModel.dispatch(.deleteMedia) {
                        router.pop()
                    }
                }
            })
        ], isRisky: true)
    }
}
