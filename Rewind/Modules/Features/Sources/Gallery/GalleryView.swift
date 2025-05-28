import SwiftUI
import UIComponents
import PhotosUI
import Domain
import Base
import Networking

public struct GalleryView: View {
    @State private var viewModel: GalleryViewModel

    private let router: GalleryRouter

    @Environment(\.showToast)
    private var showToast
    @Environment(\.isTopScreen)
    private var isTopScreen

    public init(router: GalleryRouter) {
        viewModel = .init()
        self.router = router
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                if viewModel.galleryItems.isEmpty {
                    Spacer(minLength: 0)
                    RewindNoteTextView(text: "Your gallery is empty 🫥")
                } else {
                    mediaGridView
                }
                Spacer(minLength: 0)
            }
            .background(Color.background)
            .sheet(isPresented: $viewModel.filterSettingsShown) {
                FilterView(title: UIComponentsStrings.Gallery.Filters.title) { settings in
                    print(settings)
                }
            }
            .safeAreaInset(edge: .bottom) {
                footer
            }
            .overlay {
                if let selectedMedia = viewModel.viewingBlurredMedia {
                    BlurredMediaView(
                        isPresented: $viewModel.blurredMediaShown,
                        galleryItem: selectedMedia,
                        onDelete: { galleryItem in
                            Task {
                                await viewModel.dispatch(.deleteMedia(galleryItem)) {
                                    withAnimation {
                                        viewModel.blurredMediaShown = false
                                    }
                                }
                            }
                        },
                        onLike: { galleryItem, liked in
                            Task {
                                await viewModel.dispatch(liked ? .unlikeMedia(galleryItem) : .likeMedia(galleryItem))
                            }
                        },
                        showMediaDetails: {
                            router.navigateToMediaDetails($0)
                            // Small 🩼 for mor beautiful animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                                withAnimation {
                                    viewModel.blurredMediaShown = false
                                }
                            })
                        }
                    )
                }
            }
            .onAppear {
                viewModel.set(showToast: showToast)
            }
            .onTopAppear {
                Task {
                    await viewModel.dispatch(.fetchGallery)
                    await viewModel.dispatch(.loadGroupImage)
                }
            }
            .refreshable {
                Task {
                    await viewModel.dispatch(.fetchGallery)
                    await viewModel.dispatch(.loadGroupImage)
                }
            }
            .onChange(of: viewModel.mediaSelection) { _, newValue in
                if let newValue {
                    Task { await viewModel.dispatch(.selectOneMedia(newValue)) }
                }
            }
            .confirmationDialog(
                UIComponentsStrings.Gallery.NewMedia.Dialog.title,
                isPresented: $viewModel.mediaUploadingDialogShown,
                titleVisibility: .visible
            ) {
                Button(UIComponentsStrings.Gallery.NewMedia.Dialog.one) {
                    Task { await viewModel.dispatch(.viewGallery) }
                }
                Button(UIComponentsStrings.Gallery.NewMedia.Dialog.multiple) {
                    router.navigateToMediasUploading()
                }
            }
            .photosPicker(isPresented: $viewModel.mediaPickerPresented, selection: $viewModel.mediaSelection)
            .navigationDestination(item: $viewModel.uploadingMedia) { media in
                uploadingMediaDestination(for: media) { loadedMedia in
                    Task { await viewModel.dispatch(.addMedia(loadedMedia)) }
                }.toolbar(.hidden)
            }
        }
    }

    private var headerView: some View {
        GalleryHeader(
            image: viewModel.groupImage,
            groupName: viewModel.currentGroup.name,
            onDismiss: {
                DispatchQueue.main.async {
                    router.dismiss()
                }
            },
            onAddingQuote: router.navigateToQuoteCreation,
            onAddingMedias: { Task { await viewModel.dispatch(.showMediasDialog) } }
        )
    }

    private var mediaGridView: some View {
        let mediaSpacing: CGFloat = 3
        return ScrollView {
            VStack {
                LazyVGrid(columns: Array(
                    repeating: GridItem(.flexible(), spacing: mediaSpacing),
                    count: 3
                ), spacing: mediaSpacing) {
                    ForEach(viewModel.galleryItems) { galleryItem in
                        SquareAsyncMedia(
                            url: galleryItem.memory.mediaURL,
                            type: galleryItem.memory.mediaType,
                            cornerRadius: 10
                        )
                        .onTapGesture {
                            Task {
                                await viewModel.dispatch(.viewBlurredMedia(galleryItem))
                            }
                        }
                    }
                }

                RewindNoteTextView(text: UIComponentsStrings.Note.end)
                    .padding(.vertical, 4)
            }
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func uploadingMediaDestination(
        for media: LoadedMedia,
        onSave: @escaping (LoadedMedia) -> Void
    ) -> some View {
        switch media.content {
        case .image:
            ImageUploadingView(media: media, onSave: onSave)
        case .video:
            VideoUploadingView(media: media, onSave: onSave)
        }
    }

    private var footer: some View {
        ZStack {
            HStack {
                GalleryMenu(
                    label: { RewindMediaButton(size: 50, fontSize: 28, type: .plus) {} },
                    onAddingQuote: router.navigateToQuoteCreation,
                    onAddingMedias: { Task { await viewModel.dispatch(.showMediasDialog) } }
                )

                Spacer()

                RewindMediaButton(size: 60, fontSize: 28, type: .rewind) { router.dismiss() }

                Spacer()

                RewindMediaButton(size: 50, fontSize: 28, type: .settings) {
                    Task { await viewModel.dispatch(.openFilters) }
                }
            }
            .padding(.horizontal, 50)
            .padding(.bottom, 20)
            .background {
                BackgroundGradientView(height: 130)
            }
        }
    }
}
