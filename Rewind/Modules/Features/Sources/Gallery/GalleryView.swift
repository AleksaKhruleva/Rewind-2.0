import SwiftUI
import UIComponents
import PhotosUI
import Domain

public struct GalleryView: View {
    @State private var viewModel: GalleryViewModel

    private let router: GalleryRouter

    @Environment(\.showToast)
    private var showToast
    
    public init(router: GalleryRouter) {
        viewModel = .init()
        self.router = router
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GalleryHeader(
                    image: UIComponentsAsset.media5.image,
                    groupName: "Group name",
                    onDismiss: {
                        DispatchQueue.main.async {
                            router.dismiss()
                        }
                    },
                    onAddingQuote: router.navigateToQuoteCreation,
                    onAddingMedias:  { Task { await viewModel.dispatch(.showMediasDialog) } }
                )
                
                let mediaSpacing: CGFloat = 3
                ScrollView {
                    VStack {
                        LazyVGrid(columns: Array(
                            repeating: GridItem(.flexible(), spacing: mediaSpacing),
                            count: 3
                        ), spacing: mediaSpacing) {
                            let medias = GalleryConstants.galleryMedias
                            ForEach(medias, id: \.self) { media in
                                Rectangle()
                                    .toSquare(media, cornerRadius: 10)
                                    .onTapGesture {
                                        Task {
                                            await viewModel.dispatch(.viewBlurredMedia(media))
                                        }
                                    }
                            }
                        }
                        
                        RewindNoteTextView(text: UIComponentsStrings.Note.end)
                            .padding(.vertical, 4)
                    }
                }
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom) {
                    ZStack(alignment: .bottom) {
                        footer
                    }
                }
                
                Spacer(minLength: 0)
            }
            .background(Color.background)
            .sheet(isPresented: $viewModel.filterSettingsShown) {
                FilterView(title: UIComponentsStrings.Gallery.Filters.title) { settings in
                    print(settings)
                }
            }
            .overlay {
                if let selectedMedia = viewModel.viewingBlurredMedia {
                    BlurredMediaView(
                        image: selectedMedia,
                        isPresented: $viewModel.blurredMediaShown,
                        showMediaDetails: router.navigateToMediaDetails
                    )
                }
            }
            .onAppear {
                viewModel.set(showToast: showToast)
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
                uploadingMediaDestination(for: media) { readyMedia in
                    // TODO: Saving here
                    print("Saving")
                }.toolbar(.hidden)
            }
        }
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
                    onAddingMedias:  { Task { await viewModel.dispatch(.showMediasDialog) } }
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
